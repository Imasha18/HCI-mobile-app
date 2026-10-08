const mongoose = require('mongoose');
const User = require('../models/User');

function authorizeRoles(...allowedRoles) {
  return async (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: 'Forbidden: Insufficient permissions' });
    }

    if (mongoose.connection.readyState === 1) {
      try {
        const user = await User.findById(req.user.id);
        if (!user) {
          return res.status(403).json({ success: false, message: 'Forbidden: User not found' });
        }
        if (user.isBlocked) {
          return res.status(403).json({ success: false, message: 'Forbidden: Account suspended' });
        }
        if (!allowedRoles.includes(user.role)) {
          return res.status(403).json({ success: false, message: 'Forbidden: Insufficient permissions' });
        }
        req.currentUser = user;
      } catch (err) {
        return res.status(500).json({ success: false, message: 'Authorization error' });
      }
    }

    return next();
  };
}

module.exports = { authorizeRoles, authorize: authorizeRoles };
