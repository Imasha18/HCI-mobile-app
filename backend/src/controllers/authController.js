const bcrypt = require('bcryptjs');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const { sendSuccess } = require('../utils/apiResponse');

async function register(req, res) {
  const { name, email, password } = req.body;
  const existing = await User.findOne({ email });
  if (existing) return res.status(409).json({ success: false, message: 'Email is already registered' });
  const hashedPassword = await bcrypt.hash(password, 12);
  const user = await User.create({ name: name.trim(), email: email.trim().toLowerCase(), password: hashedPassword, role: 'customer' });
  return sendSuccess(res, { user: { id: user.id, name: user.name, email: user.email, role: user.role }, token: generateToken(user) }, 'Account created', 201);
}

async function login(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const { password } = req.body;
  const user = await User.findOne({ email }).select('+password');
  if (!user || !(await bcrypt.compare(password, user.password))) return res.status(401).json({ success: false, message: 'Invalid email or password' });
  if (user.role !== 'customer') return res.status(403).json({ success: false, message: 'Customer access only' });
  return sendSuccess(res, { user: { id: user.id, name: user.name, email: user.email, role: user.role }, token: generateToken(user) }, 'Signed in');
}

async function me(req, res) {
  const user = await User.findById(req.user.id).select('-password');
  return sendSuccess(res, user);
}

module.exports = { register, login, me };
