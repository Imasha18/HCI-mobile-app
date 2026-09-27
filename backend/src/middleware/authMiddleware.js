const jwt = require('jsonwebtoken');
const environment = require('../config/environment');

function authenticate(req, res, next) {
  const token = req.headers.authorization?.startsWith('Bearer ')
    ? req.headers.authorization.slice(7)
    : null;
  if (!token) return res.status(401).json({ success: false, message: 'Authentication required' });
  try {
    req.user = jwt.verify(token, environment.jwtSecret);
    return next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
}

module.exports = { authenticate };
