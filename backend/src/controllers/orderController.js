const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Meal = require('../models/Meal');
const Notification = require('../models/Notification');
const Earning = require('../models/Earning');
const { sendSuccess } = require('../utils/apiResponse');

async function listOrders(req, res) {
  // If user is cook, return cook's orders, else customer's orders
  const filter = req.user.role === 'cook' ? { cook: req.user.id } : { customer: req.user.id };
  const orders = await Order.find(filter)
    .populate('customer', 'name phone address')
    .populate('cook', 'name kitchenName phone')
    .populate('items.meal', 'name imageUrl price category');
  return sendSuccess(res, orders);
}

async function createOrder(req, res) {
  const cart = await Cart.findOne({ customer: req.user.id }).populate('items.meal');
  const sourceItems = req.body.items || cart?.items || [];
  if (!sourceItems.length) return res.status(400).json({ success: false, message: 'Cart is empty' });
  const items = sourceItems.map((item) => ({
    meal: item.meal?._id || item.meal,
    name: item.name || item.meal?.name,
    quantity: Number(item.quantity || 1),
    price: Number(item.price ?? item.meal?.price ?? 0),
  }));
  const meals = await Meal.find({ _id: { $in: items.map((item) => item.meal) } });
  if (!meals.length) return res.status(400).json({ success: false, message: 'One or more meals are invalid' });
  const total = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const cookId = req.body.cookId || req.body.cook || meals[0].cook;

  const order = await Order.create({
    ...req.body,
    customer: req.user.id,
    cook: cookId,
    items,
    total,
    status: 'Order Received',
  });

  await Cart.deleteOne({ customer: req.user.id });

  // Notifications
  await Notification.create({
    user: req.user.id,
    title: 'Order Placed',
    body: `Your order #${order.id} has been placed successfully.`,
  });

  if (cookId) {
    await Notification.create({
      user: cookId,
      title: 'New Order Received',
      body: `You received a new order #${order.id} totaling \$${total.toFixed(2)}.`,
    });
  }

  return sendSuccess(res, order, 'Order created', 201);
}

async function getOrder(req, res) {
  const query = { _id: req.params.id };
  if (req.user.role === 'customer') {
    query.customer = req.user.id;
  } else if (req.user.role === 'cook') {
    query.cook = req.user.id;
  }

  const order = await Order.findOne(query)
    .populate('customer', 'name phone address')
    .populate('cook', 'name kitchenName phone')
    .populate('items.meal', 'name imageUrl price category');

  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });
  return sendSuccess(res, order);
}

// PATCH /api/orders/:id/accept
async function acceptOrder(req, res) {
  const query = { _id: req.params.id };
  if (req.user.role === 'cook') query.cook = req.user.id;

  const order = await Order.findOne(query);
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

  order.status = 'Accepted';
  await order.save();

  await Notification.create({
    user: order.customer,
    title: 'Order Accepted',
    body: `Great news! The kitchen accepted your order #${order.id}.`,
  });

  return sendSuccess(res, order, 'Order accepted successfully');
}

// PATCH /api/orders/:id/reject
async function rejectOrder(req, res) {
  const query = { _id: req.params.id };
  if (req.user.role === 'cook') query.cook = req.user.id;

  const order = await Order.findOne(query);
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

  order.status = 'Rejected';
  await order.save();

  await Notification.create({
    user: order.customer,
    title: 'Order Cancelled',
    body: `The kitchen was unable to fulfill order #${order.id}. Any payment will be refunded.`,
  });

  return sendSuccess(res, order, 'Order rejected');
}

// PATCH /api/orders/:id/status
async function updateOrderStatus(req, res) {
  const { status } = req.body;
  if (!status) return res.status(400).json({ success: false, message: 'Status is required' });

  const query = { _id: req.params.id };
  if (req.user.role === 'cook') query.cook = req.user.id;

  const order = await Order.findOne(query);
  if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

  order.status = status;
  await order.save();

  // If completed or ready, register earnings record if not yet created
  if (status === 'Completed' || status === 'Ready For Pickup') {
    const existingEarning = await Earning.findOne({ orderId: order._id });
    if (!existingEarning) {
      await Earning.create({
        cookId: order.cook,
        orderId: order._id,
        amount: order.total,
        date: new Date(),
      });
    }
  }

  // Notify customer
  await Notification.create({
    user: order.customer,
    title: `Order Status: ${status}`,
    body: `Your order #${order.id} is now ${status}.`,
  });

  return sendSuccess(res, order, `Order status updated to ${status}`);
}

module.exports = {
  listOrders,
  createOrder,
  getOrder,
  acceptOrder,
  rejectOrder,
  updateOrderStatus,
};
