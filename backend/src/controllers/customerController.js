const User = require('../models/User');
const { sendSuccess } = require('../utils/apiResponse');
const { isValidPhone, normalizePhone } = require('../validators/authValidator');

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
    profileImage: user.profileImage || '',
    isVerified: user.isVerified ?? true,
    rating: user.rating || 4.8,
    isOnline: user.isOnline ?? true,
    emailVerified: user.emailVerified,
    preferences: user.preferences || {},
  };
}

async function getCustomerSummary(req, res) {
  return sendSuccess(res, { userId: req.user.id, message: 'Customer workspace ready' });
}

async function getCustomerProfile(req, res) {
  const user = await User.findById(req.user.id).select('-password');
  if (!user) return res.status(404).json({ success: false, message: 'Customer not found' });
  return sendSuccess(res, publicUser(user));
}

async function updateCustomerProfile(req, res) {
  const { name, phone, address, town, city, profileImage } = req.body;
  const updates = {};
  if (name && typeof name === 'string' && name.trim().length >= 2) {
    updates.name = name.trim();
  }
  if (phone !== undefined) {
    if (phone && !isValidPhone(phone)) {
      return res.status(400).json({ success: false, message: 'Enter a valid Sri Lankan phone number (e.g. 077 123 4567)' });
    }
    updates.phone = normalizePhone(phone);
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
  if (profileImage !== undefined) {
    updates.profileImage = profileImage;
  }

  const user = await User.findByIdAndUpdate(req.user.id, updates, { new: true });
  if (!user) return res.status(404).json({ success: false, message: 'Customer not found' });
  return sendSuccess(res, publicUser(user), 'Profile updated successfully');
}

module.exports = {
  getCustomerSummary,
  getCustomerProfile,
  updateCustomerProfile,
};
