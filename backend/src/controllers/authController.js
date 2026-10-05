const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const { sendSuccess } = require('../utils/apiResponse');
const environment = require('../config/environment');
const { sendVerificationCode, sendPasswordResetCode } = require('../services/emailService');
const { notifyAdminNewVerification } = require('../services/notificationService');

function publicUser(user) {
  return {
    id: user.id || user._id,
    name: user.name,
    email: user.email,
    role: user.role,
    phone: user.phone || '',
    address: user.address || '',
    profileImage: user.profileImage || '',
    isVerified: user.isVerified ?? true,
    rating: user.rating || 4.8,
    isOnline: user.isOnline ?? true,
    kitchenName: user.kitchenName || (user.name ? `${user.name}'s Kitchen` : 'Home Kitchen'),
    vehicleDetails: user.vehicleDetails || { type: 'Motorbike', model: 'Honda Dio', plateNumber: 'WP BZ-4892' },
    emailVerified: user.emailVerified,
    isBlocked: user.isBlocked ?? false,
    verificationStatus: user.verificationStatus || 'approved',
  };
}

function createVerificationCode() {
  return String(crypto.randomInt(100000, 1000000));
}

async function register(req, res) {
  const { role } = req.body;
  if (role === 'cook') {
    return registerCook(req, res);
  }
  if (role === 'rider') {
    return registerRider(req, res);
  }

  const { name, email, password, phone, address } = req.body;
  const existing = await User.findOne({ email: email.trim().toLowerCase() });
  if (existing) return res.status(409).json({ success: false, message: 'Email is already registered' });
  const hashedPassword = await bcrypt.hash(password, 12);

  const code = createVerificationCode();
  const user = await User.create({
    name: name.trim(),
    email: email.trim().toLowerCase(),
    password: hashedPassword,
    phone: phone?.trim(),
    address: address?.trim(),
    role: 'customer',
    emailVerified: false,
    verificationCodeHash: crypto.createHash('sha256').update(code).digest('hex'),
    verificationExpiresAt: Date.now() + environment.verificationUrlMinutes * 60 * 1000,
  });
  await sendVerificationCode(user.email, code);
  return sendSuccess(res, { user: publicUser(user), emailVerificationRequired: true }, 'Verification code sent', 201);
}

async function registerRider(req, res) {
  try {
    const { name, email, password, phone, address, vehicleType, vehicleModel, vehiclePlateNumber } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }
    const normalizedEmail = email.trim().toLowerCase();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) return res.status(409).json({ success: false, message: 'Email is already registered' });
    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      role: 'rider',
      phone: phone?.trim() || '+94 77 123 4567',
      address: address?.trim() || 'Colombo, Sri Lanka',
      vehicleDetails: {
        type: vehicleType?.trim() || 'Motorbike',
        model: vehicleModel?.trim() || 'Honda Dio',
        plateNumber: vehiclePlateNumber?.trim() || 'WP BZ-4892',
      },
      isVerified: true,
      emailVerified: true,
      verificationStatus: 'approved',
      verificationDocuments: [
        { title: 'Driving License (Front & Back)', documentUrl: 'https://homebite.lk/docs/license.pdf', status: 'approved' },
        { title: 'Vehicle Revenue License 2026', documentUrl: 'https://homebite.lk/docs/revenue.pdf', status: 'approved' },
      ],
    });
    notifyAdminNewVerification(user).catch(() => {});
    return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Rider registered successfully', 201);
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
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
    if (existing) return res.status(409).json({ success: false, message: 'Email is already registered' });
    const hashedPassword = await bcrypt.hash(password, 12);
    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      role: 'cook',
      phone: phone?.trim() || '+94 77 123 4567',
      address: address?.trim() || 'Colombo, Sri Lanka',
      kitchenName: kitchenName?.trim() || `${name.trim()}'s Kitchen`,
      isVerified: true,
      emailVerified: true,
      verificationStatus: 'approved',
      verificationDocuments: [
        { title: 'Food Hygiene Certificate', documentUrl: 'https://homebite.lk/cert/hygiene.pdf', status: 'approved' },
        { title: 'National Identity Card (NIC)', documentUrl: 'https://homebite.lk/nic/front.jpg', status: 'approved' },
      ],
    });
    notifyAdminNewVerification(user).catch(() => {});
    return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Cook registered successfully', 201);
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
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
    return res.status(403).json({ success: false, message: `${role.charAt(0).toUpperCase() + role.slice(1)} access only` });
  }
  if (user.role === 'customer' && !user.emailVerified) {
    return res.status(403).json({ success: false, message: 'Please verify your email before signing in' });
  }
  return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Signed in');
}

async function verifyEmail(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const codeHash = crypto.createHash('sha256').update(req.body.code.trim()).digest('hex');
  const user = await User.findOne({ email }).select('+verificationCodeHash +verificationExpiresAt');
  if (!user || user.verificationCodeHash !== codeHash || !user.verificationExpiresAt || user.verificationExpiresAt.getTime() < Date.now()) return res.status(400).json({ success: false, message: 'Invalid or expired verification code' });
  user.emailVerified = true;
  user.verificationCodeHash = undefined;
  user.verificationExpiresAt = undefined;
  await user.save();
  return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Email verified');
}

async function googleLogin(req, res) {
  if (!environment.googleClientId) return res.status(503).json({ success: false, message: 'Google authentication is not configured' });
  const client = new OAuth2Client(environment.googleClientId);
  const ticket = await client.verifyIdToken({ idToken: req.body.idToken, audience: environment.googleClientId });
  const payload = ticket.getPayload();
  if (!payload?.email || !payload.email_verified) return res.status(401).json({ success: false, message: 'A verified Google email is required' });
  let user = await User.findOne({ email: payload.email.toLowerCase() });
  if (!user) user = await User.create({ name: payload.name || payload.email.split('@')[0], email: payload.email.toLowerCase(), password: await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 12), role: 'customer', emailVerified: true, googleId: payload.sub, profileImage: payload.picture });
  if (user.role !== 'customer') return res.status(403).json({ success: false, message: 'Customer access only' });
  return sendSuccess(res, { user: publicUser(user), token: generateToken(user) }, 'Signed in with Google');
}

async function requestPasswordReset(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const user = await User.findOne({ email, role: 'customer' });
  if (user) {
    const code = createVerificationCode();
    user.resetCodeHash = crypto.createHash('sha256').update(code).digest('hex');
    user.resetExpiresAt = Date.now() + environment.verificationUrlMinutes * 60 * 1000;
    await user.save();
    await sendPasswordResetCode(user.email, code);
  }
  return sendSuccess(res, { email: user ? email : null }, 'If that email is registered, a reset code was sent');
}

async function resetPassword(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const codeHash = crypto.createHash('sha256').update(req.body.code.trim()).digest('hex');
  const user = await User.findOne({ email, role: 'customer' }).select('+resetCodeHash +resetExpiresAt');
  if (!user || user.resetCodeHash !== codeHash || !user.resetExpiresAt || user.resetExpiresAt.getTime() < Date.now()) return res.status(400).json({ success: false, message: 'Invalid or expired password reset code' });
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
  const { name, phone, address, profileImage } = req.body;
  const updates = {};
  if (name && typeof name === 'string' && name.trim().length >= 2) updates.name = name.trim();
  if (phone !== undefined) {
    const { isValidPhone } = require('../validators/authValidator');
    if (phone && !isValidPhone(phone)) {
      return res.status(400).json({ success: false, message: 'Enter a valid Sri Lankan phone number (e.g. 077 123 4567)' });
    }
    updates.phone = phone.trim();
  }
  if (address !== undefined) {
    if (address && address.trim().length < 5) {
      return res.status(400).json({ success: false, message: 'Please enter a complete delivery address' });
    }
    updates.address = address.trim();
  }
  if (profileImage !== undefined) updates.profileImage = profileImage;

  const user = await User.findByIdAndUpdate(req.user.id, updates, { new: true });
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  return sendSuccess(res, publicUser(user), 'Profile updated successfully');
}

module.exports = { register, registerCook, registerRider, login, verifyEmail, googleLogin, requestPasswordReset, resetPassword, me, updateMe, publicUser };
