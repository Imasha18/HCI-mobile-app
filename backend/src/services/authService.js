const bcrypt = require('bcryptjs');

async function hashPassword(password) {
  return bcrypt.hash(password, 12);
}

module.exports = { hashPassword };
