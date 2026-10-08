const mongoose = require('mongoose');
const User = require('../models/User');

function authorizeRoles(...allowedRoles) {
  return async (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }

    if (req.user.role === 'admin') {
      return next();
    }

    if (mongoose.connection.readyState === 1) {
      try {
        const user = await User.findById(req.user.id);
        if (!user) {
          if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ success: false, message: 'Forbidden: Insufficient permissions' });
          }
          return next();
        }

        if (user.isBlocked) {
          return res.status(403).json({ success: false, message: 'Forbidden: Account suspended' });
        }

        if (user.role === 'admin') {
          req.currentUser = user;
          return next();
        }

        // Enable cook functionality for authenticated users accessing cook features
        if (allowedRoles.includes('cook') && user.role === 'customer') {
          user.role = 'cook';
          if (!user.kitchenName) {
            user.kitchenName = `${user.name || 'Home Cook'}'s Kitchen`;
          }
          await user.save();
          req.user.role = 'cook';
          req.currentUser = user;
          return next();
        }

        if (!allowedRoles.includes(user.role)) {
          return res.status(403).json({ success: false, message: 'Forbidden: Insufficient permissions' });
        }

        req.currentUser = user;
        return next();
      } catch (err) {
        return res.status(500).json({ success: false, message: 'Authorization error' });
      }
    }

    if (allowedRoles.includes(req.user.role)) {
      return next();
    }

    return res.status(403).json({ success: false, message: 'Forbidden: Insufficient permissions' });
  };
}

module.exports = { authorizeRoles, authorize: authorizeRoles };
