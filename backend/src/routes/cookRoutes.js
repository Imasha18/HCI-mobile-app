const express = require('express');
const {
  getCookProfile,
  getMyProfile,
  updateMyProfile,
  getCookDashboard,
  getCookMeals,
  getCookOrders,
  getCookOrderById,
  getCookEarnings,
} = require('../controllers/cookController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();

// Specific routes first before /:id parameter
router.get('/profile', authenticate, authorizeRoles('cook'), getMyProfile);
router.put('/profile', authenticate, authorizeRoles('cook'), updateMyProfile);
router.get('/dashboard', authenticate, authorizeRoles('cook'), getCookDashboard);
router.get('/summary', authenticate, authorizeRoles('cook'), getCookDashboard);
router.get('/meals', authenticate, authorizeRoles('cook'), getCookMeals);
router.get('/orders', authenticate, authorizeRoles('cook'), getCookOrders);
router.get('/orders/:id', authenticate, authorizeRoles('cook'), getCookOrderById);
router.get('/earnings', authenticate, authorizeRoles('cook'), getCookEarnings);

// Public profile by cook id
router.get('/:id', getCookProfile);

module.exports = router;
