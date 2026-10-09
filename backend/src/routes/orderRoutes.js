const express = require('express');
const {
  listOrders,
  createOrder,
  getOrder,
  acceptOrder,
  rejectOrder,
  updateOrderStatus,
} = require('../controllers/orderController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();
router.use(authenticate);

router.route('/')
  .get(listOrders)
  .post(authorizeRoles('customer', 'admin'), createOrder);

router.get('/:id', getOrder);
router.patch('/:id/accept', authorizeRoles('cook', 'admin'), acceptOrder);
router.patch('/:id/reject', authorizeRoles('cook', 'admin'), rejectOrder);
router.patch('/:id/status', authorizeRoles('cook', 'rider', 'admin'), updateOrderStatus);

module.exports = router;
