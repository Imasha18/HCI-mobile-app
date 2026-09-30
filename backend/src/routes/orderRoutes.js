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

const router = express.Router();
router.use(authenticate);

router.route('/').get(listOrders).post(createOrder);
router.get('/:id', getOrder);
router.patch('/:id/accept', acceptOrder);
router.patch('/:id/reject', rejectOrder);
router.patch('/:id/status', updateOrderStatus);

module.exports = router;
