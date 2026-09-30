const express = require('express');
const {
  createDelivery,
  listDeliveries,
  getAvailableDeliveries,
  getDeliveryById,
  acceptDelivery,
  pickupDelivery,
  startDelivery,
  completeDelivery,
  updateDelivery,
  cancelDelivery,
  deleteDelivery,
} = require('../controllers/deliveryController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();

router.use(authenticate);

// CRUD Endpoints
router.get('/', authorizeRoles('rider', 'admin', 'cook'), listDeliveries);
router.post('/', authorizeRoles('rider', 'admin', 'cook', 'customer'), createDelivery);
router.get('/available', authorizeRoles('rider', 'admin'), getAvailableDeliveries);
router.get('/:id', authorizeRoles('rider', 'admin', 'cook', 'customer'), getDeliveryById);

// Delivery Workflow
router.patch('/:id/accept', authorizeRoles('rider', 'admin'), acceptDelivery);
router.patch('/:id/pickup', authorizeRoles('rider', 'admin'), pickupDelivery);
router.patch('/:id/start', authorizeRoles('rider', 'admin'), startDelivery);
router.patch('/:id/complete', authorizeRoles('rider', 'admin'), completeDelivery);
router.patch('/:id/cancel', authorizeRoles('rider', 'admin', 'cook'), cancelDelivery);

// Management CRUD
router.put('/:id', authorizeRoles('rider', 'admin'), updateDelivery);
router.delete('/:id', authorizeRoles('rider', 'admin'), deleteDelivery);

module.exports = router;
