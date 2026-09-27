const jwt = require('jsonwebtoken');
const environment = require('../config/environment');

function generateToken(user) {
  return jwt.sign({ id: user._id, role: user.role }, environment.jwtSecret, { expiresIn: '7d' });
}

module.exports = generateToken;
