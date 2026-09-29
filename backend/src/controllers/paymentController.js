const { sendSuccess } = require('../utils/apiResponse');
const Payment = require('../models/Payment');
const Order = require('../models/Order');

async function createPayment(req, res) {
  const order = await Order.findOne({ _id: req.body.orderId, customer: req.user.id });
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
  const payment = await Payment.create({ order: order.id, amount: order.total, provider: req.body.provider || 'card', status: 'paid', transactionId: `hb_${Date.now()}` });
  order.paymentStatus = 'paid';
  order.status = 'confirmed';
  await order.save();
  return sendSuccess(res, payment, 'Payment completed', 201);
}

module.exports = { createPayment };
