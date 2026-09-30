const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, select: false },
  role: { type: String, enum: ['customer', 'cook', 'rider', 'admin'], default: 'customer' },
  phone: String,
  address: String,
  profileImage: String,
  emailVerified: { type: Boolean, default: false },
  verificationCodeHash: { type: String, select: false },
  verificationExpiresAt: { type: Date, select: false },
  resetCodeHash: { type: String, select: false },
  resetExpiresAt: { type: Date, select: false },
  googleId: { type: String, unique: true, sparse: true },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
