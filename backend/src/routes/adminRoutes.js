const express = require('express');
const { getAdminSummary } = require('../controllers/adminController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('admin'), getAdminSummary);
module.exports = router;
