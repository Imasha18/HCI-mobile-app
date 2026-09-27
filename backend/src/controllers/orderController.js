const Order = require('../models/Order');
const { sendSuccess } = require('../utils/apiResponse');

async function listOrders(req, res) {
  const orders = await Order.find({ customer: req.user.id }).populate('items.meal');
  return sendSuccess(res, orders);
}

async function createOrder(req, res) {
  const order = await Order.create({ ...req.body, customer: req.user.id });
  return sendSuccess(res, order, 'Order created', 201);
}

async function getOrder(req, res) {
  const order = await Order.findOne({ _id: req.params.id, customer: req.user.id }).populate('items.meal');
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
  return sendSuccess(res, order);
}

module.exports = { listOrders, createOrder, getOrder };
