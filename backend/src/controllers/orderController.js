const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Meal = require('../models/Meal');
const Notification = require('../models/Notification');
const { sendSuccess } = require('../utils/apiResponse');

async function listOrders(req, res) {
  const orders = await Order.find({ customer: req.user.id }).populate('items.meal');
  return sendSuccess(res, orders);
}

async function createOrder(req, res) {
  const cart = await Cart.findOne({ customer: req.user.id }).populate('items.meal');
  const sourceItems = req.body.items || cart?.items || [];
  if (!sourceItems.length) return res.status(400).json({ success: false, message: 'Cart is empty' });
  const items = sourceItems.map((item) => ({
    meal: item.meal?._id || item.meal,
    quantity: Number(item.quantity),
    price: Number(item.price ?? item.meal?.price),
  }));
  const meals = await Meal.find({ _id: { $in: items.map((item) => item.meal) }, available: true });
  if (meals.length !== items.length) return res.status(400).json({ success: false, message: 'One or more meals are unavailable' });
  const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const order = await Order.create({ ...req.body, customer: req.user.id, cook: meals[0].cook, items, total, status: 'pending' });
  await Cart.deleteOne({ customer: req.user.id });
  await Notification.create({ user: req.user.id, title: 'Order placed', body: `Order ${order.id} has been placed.` });
  return sendSuccess(res, order, 'Order created', 201);
}

async function getOrder(req, res) {
  const order = await Order.findOne({ _id: req.params.id, customer: req.user.id }).populate('items.meal');
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
  return sendSuccess(res, order);
}

module.exports = { listOrders, createOrder, getOrder };
