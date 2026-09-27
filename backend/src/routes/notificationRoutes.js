const express = require('express');
const { listNotifications } = require('../controllers/notificationController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.get('/', authenticate, listNotifications);
module.exports = router;
