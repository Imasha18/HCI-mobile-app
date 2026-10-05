const User = require('../models/User');
const { sendSuccess } = require('../utils/apiResponse');
const { isValidPhone } = require('../validators/authValidator');

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
  const { name, phone, address, profileImage } = req.body;
  const updates = {};
  if (name && typeof name === 'string' && name.trim().length >= 2) {
    updates.name = name.trim();
  }
  if (phone !== undefined) {
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
