const express = require('express');
const { getCustomerSummary, getCustomerProfile, updateCustomerProfile } = require('../controllers/customerController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('customer'), getCustomerSummary);
router.get('/profile', authenticate, authorizeRoles('customer'), getCustomerProfile);
router.put('/profile', authenticate, authorizeRoles('customer'), updateCustomerProfile);

module.exports = router;
