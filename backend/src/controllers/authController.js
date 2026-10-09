const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const PendingRegistration = require('../models/PendingRegistration');
const generateToken = require('../utils/generateToken');
const { sendSuccess } = require('../utils/apiResponse');
const environment = require('../config/environment');
const { sendVerificationCode, sendPasswordResetCode } = require('../services/emailService');
const { notifyAdminNewVerification } = require('../services/notificationService');
const { normalizePhone } = require('../validators/authValidator');

function extractTown(address) {
  if (!address || typeof address !== 'string') return '';
  const cleaned = address.trim().replace(/,\s*Sri Lanka$/i, '').trim();
  if (!cleaned) return '';

  const colomboMatch = cleaned.match(/colombo[\s-]*(?:0?[1-9]|1[0-5])\b/i);
  if (colomboMatch) {
    const digits = colomboMatch[0].replace(/[^0-9]/g, '');
    if (digits) {
      return `Colombo ${digits.padStart(2, '0')}`;
    }
    return 'Colombo';
  }

  const parts = cleaned.split(',').map((p) => p.trim()).filter(Boolean);
  if (parts.length === 0) return '';

  for (let i = parts.length - 1; i >= 0; i--) {
    let part = parts[i];
    if (/^sri lanka$/i.test(part)) continue;
    if (/^(lk-?)?\d{4,6}$/i.test(part)) continue;
    part = part.replace(/[-,\s]*\b\d{4,6}\b.*$/, '').trim();
    if (part.length > 0) {
      return part.split(' ').map((w) => (w ? w.charAt(0).toUpperCase() + w.slice(1).toLowerCase() : '')).join(' ');
    }
  }

  return parts[parts.length - 1];
}

function publicUser(user) {
  const town = user.town || user.city || extractTown(user.address) || 'Colombo 03';
  return {
    id: user.id || user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    phone: user.phone || '',
    address: user.address || '',
    town,
    city: user.city || town,
    isVerified: user.isVerified ?? (user.role === 'rider' ? false : true),
    rating: user.rating || 4.8,
    isOnline: user.isOnline ?? true,
    kitchenName: user.kitchenName || (user.name ? `${user.name}'s Kitchen` : 'Home Kitchen'),
    vehicleDetails: {
      type: user.vehicleDetails?.type || 'Motorbike',
      model: user.vehicleDetails?.model || '',
      plateNumber: user.vehicleDetails?.plateNumber || '',
    },
    emailVerified: user.emailVerified,
    isBlocked: user.isBlocked ?? false,
    verificationStatus: user.verificationStatus || (user.role === 'rider' ? 'not_submitted' : 'approved'),
    verificationDocuments: user.verificationDocuments || {},
  };
}

function createVerificationCode() {
  return String(crypto.randomInt(100000, 1000000));
}

async function register(req, res) {
  try {
    const { role } = req.body;
    if (role === 'cook') {
      return registerCook(req, res);
    }
    if (role === 'rider') {
      return registerRider(req, res);
    }

    const { name, email, password, phone, address } = req.body;
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) return res.status(409).json({ success: false, message: 'An account already exists with this email.' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const normalizedPhone = normalizePhone(phone);
    const code = createVerificationCode();
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + environment.verificationUrlMinutes * 60 * 1000);

    // Store in temporary PendingRegistration collection; do not permanently save User until OTP verification
    await PendingRegistration.findOneAndUpdate(
      { email: normalizedEmail },
      {
        name: name.trim(),
        email: normalizedEmail,
        password: hashedPassword,
        phone: normalizedPhone,
        address: address?.trim() || '',
        role: 'customer',
        verificationCodeHash: codeHash,
        verificationExpiresAt: expiresAt,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await sendVerificationCode(normalizedEmail, code);

    return sendSuccess(res, {
      user: {
        name: name.trim(),
        email: normalizedEmail,
        role: 'customer',
        phone: normalizedPhone,
        address: address?.trim() || '',
        emailVerified: false,
      },
      emailVerificationRequired: true,
    }, 'Verification code sent', 201);
  } catch (error) {
    console.error('Customer registration error:', error);
    return res.status(500).json({ success: false, message: 'Unable to create account. Please try again.' });
  }
}

async function registerRider(req, res) {
  try {
    const { name, email, password, phone, address, vehicleType, vehicleModel, vehiclePlateNumber } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) return res.status(409).json({ success: false, message: 'An account already exists with this email.' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const normalizedPhone = normalizePhone(phone);
    const code = createVerificationCode();
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');
    const expiresAt = new Date(Date.now() + environment.verificationUrlMinutes * 60 * 1000);

    // Store in temporary PendingRegistration collection
    await PendingRegistration.findOneAndUpdate(
      { email: normalizedEmail },
      {
        name: name.trim(),
        email: normalizedEmail,
        password: hashedPassword,
        role: 'rider',
        phone: normalizedPhone,
        address: address?.trim() || '',
        vehicleDetails: {
          type: vehicleType?.trim() || 'Motorbike',
          model: vehicleModel?.trim() || '',
          plateNumber: vehiclePlateNumber?.trim() || '',
        },
        verificationCodeHash: codeHash,
        verificationExpiresAt: expiresAt,
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    await sendVerificationCode(normalizedEmail, code);

    return sendSuccess(res, {
      user: {
        name: name.trim(),
        email: normalizedEmail,
        role: 'rider',
        phone: normalizedPhone,
        address: address?.trim() || '',
        emailVerified: false,
      },
      emailVerificationRequired: true,
    }, 'Verification code sent', 201);
  } catch (error) {
    console.error('Rider registration error:', error);
    return res.status(500).json({ success: false, message: 'Unable to create account. Please try again.' });
  }
}

async function registerCook(req, res) {
  try {
    const { name, email, password, phone, address, kitchenName } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) return res.status(409).json({ success: false, message: 'An account already exists with this email.' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const normalizedPhone = normalizePhone(phone) || '+94 77 123 4567';
    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      role: 'cook',
      phone: normalizedPhone,
      address: address?.trim() || 'Colombo, Sri Lanka',
      kitchenName: kitchenName?.trim() || `${name.trim()}'s Kitchen`,
      isVerified: true,
      emailVerified: true,
      verificationStatus: 'approved',
      verificationDocuments: {
        nic: { type: 'nic', fileUrl: 'https://homebite.lk/nic/front.jpg', fileName: 'NIC', status: 'approved' },
      },
    });
    notifyAdminNewVerification(user).catch(() => {});
    return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Cook registered successfully', 201);
  } catch (error) {
    console.error('Cook registration error:', error);
    return res.status(500).json({ success: false, message: 'Unable to create account. Please try again.' });
  }
}

async function login(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const { password, role } = req.body;
  const user = await User.findOne({ email }).select('+password');
  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).json({ success: false, message: 'Invalid email or password' });
  }
  if (user.isBlocked) {
    return res.status(403).json({ success: false, message: 'Your account has been suspended by administration' });
  }
  if (role && user.role !== role) {
    if (role === 'cook' && user.role === 'customer') {
      user.role = 'cook';
      if (!user.kitchenName) {
        user.kitchenName = `${user.name || 'Home Cook'}'s Kitchen`;
      }
      await user.save();
    } else if (role === 'customer' && (user.role === 'cook' || user.role === 'rider')) {
      // Cooks and riders can access customer portal
    } else if (user.role === 'admin') {
      // Admin can log in to any portal
    } else {
      return res.status(403).json({ success: false, message: `${role.charAt(0).toUpperCase() + role.slice(1)} access only` });
    }
  }
  if ((user.role === 'customer' || user.role === 'rider') && !user.emailVerified) {
    return res.status(403).json({
      success: false,
      message: 'Please verify your email before signing in',
      emailVerificationRequired: true,
      email: user.email,
      role: user.role,
    });
  }
  return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Signed in');
}

async function verifyEmail(req, res) {
  try {
    const email = req.body.email.trim().toLowerCase();
    const code = req.body.code ? req.body.code.trim() : '';
    if (!code) {
      return res.status(400).json({ success: false, message: 'Verification code is required' });
    }
    const codeHash = crypto.createHash('sha256').update(code).digest('hex');

    // 1. Check temporary PendingRegistration collection
    const pending = await PendingRegistration.findOne({ email });
    if (pending) {
      if (pending.verificationCodeHash !== codeHash) {
        return res.status(400).json({ success: false, message: 'Invalid verification code' });
      }
      if (!pending.verificationExpiresAt || pending.verificationExpiresAt.getTime() < Date.now()) {
        return res.status(400).json({ success: false, message: 'Verification code has expired. Please request a new one' });
      }

      // Check permanent User again before creating
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        await PendingRegistration.deleteOne({ _id: pending._id });
        return res.status(409).json({ success: false, message: 'An account already exists with this email.' });
      }

      const isRider = pending.role === 'rider';
      const user = await User.create({
        name: pending.name,
        email: pending.email,
        password: pending.password,
        role: pending.role,
        phone: pending.phone || '',
        address: pending.address || '',
        town: extractTown(pending.address || ''),
        city: extractTown(pending.address || ''),
        kitchenName: pending.kitchenName,
        vehicleDetails: pending.vehicleDetails || { type: 'Motorbike', model: '', plateNumber: '' },
        emailVerified: true,
        isVerified: !isRider,
        verificationStatus: isRider ? 'not_submitted' : 'approved',
        verificationDocuments: isRider ? {
          nic: { type: 'nic', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
          drivingLicense: { type: 'drivingLicense', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
          vehicleDocument: { type: 'vehicleDocument', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
          insurance: { type: 'insurance', fileUrl: '', fileName: '', status: 'not_submitted', rejectionReason: null, uploadedAt: null, approvedAt: null, approvedBy: null },
        } : {},
      });

      // Cleanup temporary registration (single-use OTP)
      await PendingRegistration.deleteOne({ _id: pending._id });

      if (isRider) {
        notifyAdminNewVerification(user).catch(() => {});
      }

      return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Email verified');
    }

    // 2. Fallback for existing unverified User records
    const user = await User.findOne({ email }).select('+verificationCodeHash +verificationExpiresAt');
    if (!user || user.verificationCodeHash !== codeHash || !user.verificationExpiresAt || user.verificationExpiresAt.getTime() < Date.now()) {
      return res.status(400).json({ success: false, message: 'Invalid or expired verification code' });
    }

    user.emailVerified = true;
    user.verificationCodeHash = undefined;
    user.verificationExpiresAt = undefined;
    await user.save();

    return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Email verified');
  } catch (error) {
    console.error('Verify email error:', error);
    return res.status(500).json({ success: false, message: 'Unable to verify email. Please try again.' });
  }
}

async function resendVerification(req, res) {
  try {
    const email = req.body.email?.trim()?.toLowerCase();
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    // 1. Check PendingRegistration
    const pending = await PendingRegistration.findOne({ email });
    if (pending) {
      if (pending.verificationExpiresAt) {
        const totalDurationMs = environment.verificationUrlMinutes * 60 * 1000;
        const timeSinceLastCodeMs = totalDurationMs - (pending.verificationExpiresAt.getTime() - Date.now());
        const cooldownMs = 60 * 1000;
        if (timeSinceLastCodeMs >= 0 && timeSinceLastCodeMs < cooldownMs) {
          const waitSeconds = Math.ceil((cooldownMs - timeSinceLastCodeMs) / 1000);
          return res.status(429).json({
            success: false,
            message: `Please wait ${waitSeconds} seconds before requesting a new code`,
          });
        }
      }

      const code = createVerificationCode();
      pending.verificationCodeHash = crypto.createHash('sha256').update(code).digest('hex');
      pending.verificationExpiresAt = new Date(Date.now() + environment.verificationUrlMinutes * 60 * 1000);
      await pending.save();

      await sendVerificationCode(pending.email, code);
      return sendSuccess(res, { sent: true }, 'New verification code sent');
    }

    // 2. Check User
    const user = await User.findOne({ email }).select('+verificationCodeHash +verificationExpiresAt');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (user.emailVerified) {
      return res.status(400).json({ success: false, message: 'Email is already verified' });
    }

    // Cooldown check (60 seconds)
    if (user.verificationExpiresAt) {
      const totalDurationMs = environment.verificationUrlMinutes * 60 * 1000;
      const timeSinceLastCodeMs = totalDurationMs - (user.verificationExpiresAt.getTime() - Date.now());
      const cooldownMs = 60 * 1000;
      if (timeSinceLastCodeMs >= 0 && timeSinceLastCodeMs < cooldownMs) {
        const waitSeconds = Math.ceil((cooldownMs - timeSinceLastCodeMs) / 1000);
        return res.status(429).json({
          success: false,
          message: `Please wait ${waitSeconds} seconds before requesting a new code`,
        });
      }
    }

    const code = createVerificationCode();
    user.verificationCodeHash = crypto.createHash('sha256').update(code).digest('hex');
    user.verificationExpiresAt = new Date(Date.now() + environment.verificationUrlMinutes * 60 * 1000);
    await user.save();

    await sendVerificationCode(user.email, code);

    return sendSuccess(res, { sent: true }, 'New verification code sent');
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

async function googleLogin(req, res) {
  if (!environment.googleClientId) return res.status(503).json({ success: false, message: 'Google authentication is not configured' });
  const client = new OAuth2Client(environment.googleClientId);
  let ticket;
  try {
    ticket = await client.verifyIdToken({ idToken: req.body.idToken, audience: environment.googleClientId });
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid Google authentication token' });
  }
  const payload = ticket.getPayload();
  if (!payload?.email || !payload.email_verified) return res.status(401).json({ success: false, message: 'A verified Google email is required' });
  const requestedRole = req.body.role || 'customer';
  let user = await User.findOne({ email: payload.email.toLowerCase() });
  if (!user) {
    const kitchenName = req.body.kitchenName || (requestedRole === 'cook' ? `${payload.name || 'Chef'}'s Kitchen` : undefined);
    user = await User.create({
      name: req.body.name || payload.name || payload.email.split('@')[0],
      email: payload.email.toLowerCase(),
      password: await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 12),
      role: requestedRole,
      kitchenName: kitchenName,
      phone: req.body.phone ? normalizePhone(req.body.phone) : '',
      address: req.body.address ? req.body.address.trim() : '',
      emailVerified: true,
      googleId: payload.sub,
      profileImage: payload.picture,
    });
  } else {
    if (user.isBlocked) {
      return res.status(403).json({ success: false, message: 'Your account has been suspended by administration' });
    }
    if (!user.googleId) user.googleId = payload.sub;
    if (!user.emailVerified) user.emailVerified = true;
    if (!user.profileImage && payload.picture) user.profileImage = payload.picture;
    if (requestedRole === 'cook') {
      if (user.role === 'customer') {
        user.role = 'cook';
      }
      if (req.body.kitchenName) {
        user.kitchenName = req.body.kitchenName.trim();
      } else if (!user.kitchenName) {
        user.kitchenName = `${user.name || payload.name || 'Home Cook'}'s Kitchen`;
      }
      if (req.body.phone) user.phone = normalizePhone(req.body.phone);
      if (req.body.address) user.address = req.body.address.trim();
    }
    await user.save();
  }
  return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Signed in with Google');
}

async function requestPasswordReset(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const user = await User.findOne({ email, role: 'customer' });
  if (user) {
    const code = createVerificationCode();
    user.resetCodeHash = crypto.createHash('sha256').update(code).digest('hex');
    user.resetExpiresAt = new Date(Date.now() + environment.verificationUrlMinutes * 60 * 1000);
    await user.save();
    await sendPasswordResetCode(user.email, code);
  }
  return sendSuccess(res, { email: user ? email : null }, 'If that email is registered, a reset code was sent');
}

async function resetPassword(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const codeHash = crypto.createHash('sha256').update(req.body.code.trim()).digest('hex');
  const user = await User.findOne({ email, role: 'customer' }).select('+resetCodeHash +resetExpiresAt');
  if (!user || user.resetCodeHash !== codeHash || !user.resetExpiresAt || user.resetExpiresAt.getTime() < Date.now()) {
    return res.status(400).json({ success: false, message: 'Invalid or expired password reset code' });
  }
  user.password = await bcrypt.hash(req.body.password, 12);
  user.resetCodeHash = undefined;
  user.resetExpiresAt = undefined;
  await user.save();
  return sendSuccess(res, {}, 'Password reset successfully');
}

async function me(req, res) {
  const user = await User.findById(req.user.id).select('-password');
  return sendSuccess(res, user ? publicUser(user) : null);
}

async function updateMe(req, res) {
  const { name, phone, address, town, city, profileImage } = req.body;
  const updates = {};
  if (name && typeof name === 'string' && name.trim().length >= 2) updates.name = name.trim();
  if (phone !== undefined) {
    const { isValidPhone, normalizePhone: normPh } = require('../validators/authValidator');
    if (phone && !isValidPhone(phone)) {
      return res.status(400).json({ success: false, message: 'Enter a valid Sri Lankan phone number (e.g. 077 123 4567)' });
    }
    updates.phone = normPh(phone);
  }
  if (address !== undefined) {
    if (address && address.trim().length < 5) {
      return res.status(400).json({ success: false, message: 'Please enter a complete delivery address' });
    }
    updates.address = address.trim();
    if (!town && !city) {
      updates.town = extractTown(address.trim());
    }
  }
  if (town !== undefined) updates.town = town.trim();
  if (city !== undefined) updates.city = city.trim();
  if (profileImage !== undefined) updates.profileImage = profileImage;

  const user = await User.findByIdAndUpdate(req.user.id, updates, { new: true });
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  return sendSuccess(res, publicUser(user), 'Profile updated successfully');
}

module.exports = {
  register,
  registerCook,
  registerRider,
  login,
  verifyEmail,
  resendVerification,
  googleLogin,
  requestPasswordReset,
  resetPassword,
  me,
  updateMe,
  publicUser,
};
