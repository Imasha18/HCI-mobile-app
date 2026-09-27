const express = require('express');
const { getCustomerSummary } = require('../controllers/customerController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('customer'), getCustomerSummary);
module.exports = router;
