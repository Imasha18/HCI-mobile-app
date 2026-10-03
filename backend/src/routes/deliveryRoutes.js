const express = require('express');
const {
  getAvailableDeliveries,
  getDeliveryById,
  acceptDelivery,
  pickupDelivery,
  startDelivery,
  completeDelivery,
} = require('../controllers/deliveryController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();

router.use(authenticate, authorizeRoles('rider', 'admin'));

router.get('/available', getAvailableDeliveries);
router.get('/:id', getDeliveryById);
router.patch('/:id/accept', acceptDelivery);
router.patch('/:id/pickup', pickupDelivery);
router.patch('/:id/start', startDelivery);
router.patch('/:id/complete', completeDelivery);

module.exports = router;
