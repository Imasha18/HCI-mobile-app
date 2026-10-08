const Order = require('../models/Order');
const Cart = require('../models/Cart');
const Meal = require('../models/Meal');
const User = require('../models/User');
const Delivery = require('../models/Delivery');
const Notification = require('../models/Notification');
const Earning = require('../models/Earning');
const { sendSuccess } = require('../utils/apiResponse');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

const VALID_ORDER_TRANSITIONS = {
  'order received': ['accepted', 'rejected', 'cancelled'],
  'accepted': ['preparing', 'cancelled', 'rejected'],
  'preparing': ['ready for pickup', 'ready', 'cancelled'],
  'ready for pickup': ['picked up', 'in transit', 'delivered', 'completed', 'cancelled'],
  'ready': ['picked up', 'in transit', 'delivered', 'completed', 'cancelled'],
  'picked up': ['in transit', 'delivered', 'completed', 'cancelled'],
  'in transit': ['delivered', 'completed', 'cancelled'],
  'delivered': [],
  'completed': [],
  'rejected': [],
  'cancelled': [],
};

async function listOrders(req, res) {
  // If user is cook, return cook's orders, else customer's orders
  const filter = req.user.role === 'cook' ? { cook: req.user.id } : { customer: req.user.id };

  if (req.query.page || req.query.limit) {
    const { page, limit, skip } = parsePagination(req.query, 10);
    const total = await Order.countDocuments(filter);
    const orders = await Order.find(filter)
      .populate('customer', 'name phone address')
      .populate('cook', 'name kitchenName phone address profileImage')
      .populate('rider', 'name phone vehicleDetails rating profileImage')
      .populate('items.meal', 'name imageUrl price category')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    return sendSuccess(res, orders, 'Success', 200, buildPaginationMeta(page, limit, total, orders.length));
  }

  const orders = await Order.find(filter)
    .populate('customer', 'name phone address')
    .populate('cook', 'name kitchenName phone address profileImage')
    .populate('rider', 'name phone vehicleDetails rating profileImage')
    .populate('items.meal', 'name imageUrl price category')
    .sort({ createdAt: -1 });
  return sendSuccess(res, orders);
}

async function createOrder(req, res) {
  const cart = await Cart.findOne({ customer: req.user.id }).populate('items.meal');
  const sourceItems = req.body.items || cart?.items || [];
  if (!sourceItems.length) return res.status(400).json({ success: false, message: 'Cart is empty' });

  const rawItems = sourceItems.map((item) => ({
    meal: item.meal?._id || item.meal,
    quantity: Math.max(1, parseInt(item.quantity, 10) || 1),
  }));

  const mealIds = rawItems.map((item) => item.meal).filter(Boolean);
  const meals = await Meal.find({ _id: { $in: mealIds } });
  if (!meals.length || meals.length !== mealIds.length) {
    return res.status(400).json({ success: false, message: 'One or more meals are invalid or no longer available' });
  }

  const mealMap = new Map(meals.map((m) => [m._id.toString(), m]));
  const items = [];
  let total = 0;

  for (const item of rawItems) {
    const meal = mealMap.get(item.meal.toString());
    if (!meal || !meal.available) {
      return res.status(400).json({ success: false, message: `Meal "${meal?.name || 'Item'}" is currently unavailable` });
    }
    const itemPrice = Number(meal.price || 0);
    total += itemPrice * item.quantity;
    items.push({
      meal: meal._id,
      name: meal.name,
      quantity: item.quantity,
      price: itemPrice, // Guaranteed server-side validated price
    });
  }

  // Duplicate submission protection within 5-second window
  const duplicateOrder = await Order.findOne({
    customer: req.user.id,
    createdAt: { $gte: new Date(Date.now() - 5000) },
    total,
  });
  if (duplicateOrder) {
    return sendSuccess(res, duplicateOrder, 'Order already placed', 200);
  }

  const cookId = req.body.cookId || req.body.cook || meals[0].cook;

  const [cookUser, customerUser] = await Promise.all([
    User.findById(cookId),
    User.findById(req.user.id),
  ]);

  const rawDelivery = req.body.deliveryAddress;
  let deliveryAddressObj = {};
  if (typeof rawDelivery === 'string') {
    deliveryAddressObj = {
      address: rawDelivery.trim(),
      phone: (req.body.deliveryPhone || req.body.phone || customerUser?.phone || '').trim(),
    };
  } else if (rawDelivery && typeof rawDelivery === 'object') {
    deliveryAddressObj = {
      address: (rawDelivery.address || customerUser?.address || '18 Flower Road, Colombo 07, Sri Lanka').trim(),
      phone: (rawDelivery.phone || req.body.deliveryPhone || req.body.phone || customerUser?.phone || '').trim(),
    };
  } else {
    deliveryAddressObj = {
      address: (req.body.address || customerUser?.address || '18 Flower Road, Colombo 07, Sri Lanka').trim(),
      phone: (req.body.deliveryPhone || req.body.phone || customerUser?.phone || '').trim(),
    };
  }

  const deliveryAddressString = deliveryAddressObj.address || '18 Flower Road, Colombo 07, Sri Lanka';
  const pickupAddress = cookUser?.address || '45/2 Galle Road, Colombo 03, Sri Lanka';

  const order = await Order.create({
    ...req.body,
    customer: req.user.id,
    cook: cookId,
    items,
    total,
    deliveryAddress: deliveryAddressObj,
    deliveryPhone: deliveryAddressObj.phone,
    paymentMethod: req.body.paymentMethod || 'Cash on Delivery',
    status: 'Order Received',
  });

  if (req.body.saveAsDefault && customerUser) {
    const profileUpdates = {};
    if (deliveryAddressObj.address) profileUpdates.address = deliveryAddressObj.address;
    if (deliveryAddressObj.phone) profileUpdates.phone = deliveryAddressObj.phone;
    if (Object.keys(profileUpdates).length > 0) {
      await User.findByIdAndUpdate(req.user.id, profileUpdates);
    }
  }

  await Cart.deleteOne({ customer: req.user.id });

  // Connect to Delivery Module: Immediately create available delivery request for riders
  await Delivery.create({
    orderId: order._id,
    order: order._id,
    cookId: cookId,
    customerId: req.user.id,
    pickupLocation: {
      address: pickupAddress,
      latitude: cookUser?.latitude || 6.9034,
      longitude: cookUser?.longitude || 79.8546,
    },
    deliveryLocation: {
      address: deliveryAddressString,
      latitude: customerUser?.latitude || 6.9128,
      longitude: customerUser?.longitude || 79.8653,
    },
    status: 'AVAILABLE',
    deliveryFee: 350.0,
    distanceKm: 3.8,
    estimatedMinutes: 20,
  });

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
      body: `You received a new order #${order.id} totaling Rs. ${total.toFixed(2)}.`,
    });
  }

  // Notify riders of new available delivery
  try {
    const riders = await User.find({ role: 'rider' }).limit(10);
    for (const rider of riders) {
      await Notification.create({
        user: rider._id,
        title: 'New Delivery Request',
        body: `New delivery available for Order #${order.id} from ${cookUser?.kitchenName || cookUser?.name || 'Home Cook'}.`,
      });
    }
  } catch (_) {}

  return sendSuccess(res, order, 'Order created', 201);
}

async function getOrder(req, res) {
  const query = { _id: req.params.id };
  if (req.user.role === 'customer') {
    query.customer = req.user.id;
  } else if (req.user.role === 'cook') {
    query.cook = req.user.id;
  } else if (req.user.role === 'rider') {
    query.rider = req.user.id;
  }

  const order = await Order.findOne(query)
    .populate('customer', 'name phone address')
    .populate('cook', 'name kitchenName phone address profileImage')
    .populate('rider', 'name phone vehicleDetails rating profileImage')
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

  const currentNorm = (order.status || '').trim().toLowerCase();
  if (currentNorm !== 'order received') {
    return res.status(400).json({ success: false, message: `Cannot accept order with current status "${order.status}"` });
  }

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

  const currentNorm = (order.status || '').trim().toLowerCase();
  if (!['order received', 'accepted'].includes(currentNorm)) {
    return res.status(400).json({ success: false, message: `Cannot reject order with current status "${order.status}"` });
  }

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

  const currentStatusNorm = (order.status || 'Order Received').trim().toLowerCase();
  const nextStatusNorm = status.trim().toLowerCase();

  const allowedNext = VALID_ORDER_TRANSITIONS[currentStatusNorm];
  if (allowedNext && !allowedNext.includes(nextStatusNorm)) {
    return res.status(400).json({
      success: false,
      message: `Invalid status transition: cannot change order from "${order.status}" to "${status}"`,
    });
  }

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

  // Notify assigned rider if one is assigned
  if (order.rider) {
    await Notification.create({
      user: order.rider,
      title: `Order Status: ${status}`,
      body: `Kitchen updated Order #${order.id} to ${status}.`,
    });
  }

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
