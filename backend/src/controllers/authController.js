const bcrypt = require('bcryptjs');
const crypto = require('node:crypto');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const generateToken = require('../utils/generateToken');
const { sendSuccess } = require('../utils/apiResponse');
const environment = require('../config/environment');
const { sendVerificationCode } = require('../services/emailService');

function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email, role: user.role, emailVerified: user.emailVerified };
}

function createVerificationCode() {
  return String(crypto.randomInt(100000, 1000000));
}

async function register(req, res) {
  const { name, email, password } = req.body;
  const existing = await User.findOne({ email });
  if (existing) return res.status(409).json({ success: false, message: 'Email is already registered' });
  const hashedPassword = await bcrypt.hash(password, 12);
  const code = createVerificationCode();
  const user = await User.create({ name: name.trim(), email: email.trim().toLowerCase(), password: hashedPassword, role: 'customer', emailVerified: false, verificationCodeHash: crypto.createHash('sha256').update(code).digest('hex'), verificationExpiresAt: Date.now() + environment.verificationUrlMinutes * 60 * 1000 });
  await sendVerificationCode(user.email, code);
  return sendSuccess(res, { user: publicUser(user), emailVerificationRequired: true }, 'Verification code sent', 201);
}

async function login(req, res) {
  const email = req.body.email.trim().toLowerCase();
  const { password } = req.body;
  const user = await User.findOne({ email }).select('+password');
  if (!user || !(await bcrypt.compare(password, user.password))) return res.status(401).json({ success: false, message: 'Invalid email or password' });
  if (user.role !== 'customer') return res.status(403).json({ success: false, message: 'Customer access only' });
  if (!user.emailVerified) return res.status(403).json({ success: false, message: 'Please verify your email before signing in' });
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

async function me(req, res) {
  const user = await User.findById(req.user.id).select('-password');
  return sendSuccess(res, user);
}

module.exports = { register, login, verifyEmail, googleLogin, me };
