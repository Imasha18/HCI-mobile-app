const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, select: false },
  role: { type: String, enum: ['customer', 'cook', 'rider', 'admin'], default: 'customer' },
  phone: String,
  address: String,
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
