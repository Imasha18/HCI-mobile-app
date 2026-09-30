const express = require('express');
const {
  getAdminSummary,
  getUsers,
  getCustomers,
  getCooks,
  getRiders,
  blockUser,
  unblockUser,
  deleteUser,
  verifyCook,
  verifyRider,
  getMeals,
  deleteMeal,
  getOrders,
  getComplaints,
  updateComplaint,
  getReports,
  getStatistics,
  getAdminNotifications,
} = require('../controllers/adminController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();

// Protect all admin routes with JWT and admin role authorization
router.use(authenticate, authorizeRoles('admin'));

// Dashboard & Summary
router.get('/summary', getAdminSummary);
router.get('/dashboard', getAdminSummary);

// Users Management
router.get('/users', getUsers);
router.get('/customers', getCustomers);
router.get('/cooks', getCooks);
router.get('/riders', getRiders);
router.patch('/users/:id/block', blockUser);
router.patch('/users/:id/unblock', unblockUser);
router.delete('/users/:id', deleteUser);

// Verification
router.patch('/cooks/:id/verify', verifyCook);
router.patch('/riders/:id/verify', verifyRider);

// Meal Monitoring
router.get('/meals', getMeals);
router.delete('/meals/:id', deleteMeal);

// Orders Monitoring
router.get('/orders', getOrders);

// Complaints Management
router.get('/complaints', getComplaints);
router.patch('/complaints/:id', updateComplaint);

// Reports & Statistics
router.get('/reports', getReports);
router.get('/statistics', getStatistics);

// Notifications
router.get('/notifications', getAdminNotifications);

module.exports = router;
