const express = require('express');
const {
  listNotifications,
  markNotificationAsRead,
  markAllAsRead,
  deleteNotification,
} = require('../controllers/notificationController');
const { authenticate } = require('../middleware/authMiddleware');

const router = express.Router();
router.use(authenticate);

router.get('/', listNotifications);
router.patch('/read-all', markAllAsRead);
router.patch('/:id/read', markNotificationAsRead);
router.delete('/:id', deleteNotification);

module.exports = router;
