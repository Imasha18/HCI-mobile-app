const express = require('express');
const {
  getRiderProfile,
  updateRiderProfile,
  getRiderDashboard,
  getRiderDeliveries,
  getRiderEarnings,
  updateRiderLocation,
} = require('../controllers/riderController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();

// All rider routes require rider role
router.use(authenticate, authorizeRoles('rider'));

router.get('/profile', getRiderProfile);
router.put('/profile', updateRiderProfile);
router.get('/dashboard', getRiderDashboard);
router.get('/summary', getRiderDashboard);
router.get('/deliveries', getRiderDeliveries);
router.get('/earnings', getRiderEarnings);
router.patch('/location', updateRiderLocation);

module.exports = router;
