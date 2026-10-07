const express = require('express');
const {
  getRecommendations,
  trackInteraction,
  getCustomerPreferences,
  updateCustomerPreferences,
} = require('../controllers/recommendationController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();

router.get('/meals', authenticate, authorizeRoles('customer'), getRecommendations);
router.post('/track', authenticate, authorizeRoles('customer'), trackInteraction);
router.get('/preferences', authenticate, authorizeRoles('customer'), getCustomerPreferences);
router.put('/preferences', authenticate, authorizeRoles('customer'), updateCustomerPreferences);

module.exports = router;
