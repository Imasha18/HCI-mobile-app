const express = require('express');
const { getCustomerSummary, getCustomerProfile, updateCustomerProfile } = require('../controllers/customerController');
const { getCustomerPreferences, updateCustomerPreferences } = require('../controllers/recommendationController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('customer'), getCustomerSummary);
router.get('/profile', authenticate, authorizeRoles('customer'), getCustomerProfile);
router.put('/profile', authenticate, authorizeRoles('customer'), updateCustomerProfile);
router.get('/preferences', authenticate, authorizeRoles('customer'), getCustomerPreferences);
router.put('/preferences', authenticate, authorizeRoles('customer'), updateCustomerPreferences);

module.exports = router;
