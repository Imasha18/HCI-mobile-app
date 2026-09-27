const express = require('express');
const { listOrders, createOrder, getOrder } = require('../controllers/orderController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.use(authenticate);
router.route('/').get(listOrders).post(createOrder);
router.get('/:id', getOrder);
module.exports = router;
