const { sendSuccess } = require('../utils/apiResponse');
const User = require('../models/User');
const Meal = require('../models/Meal');
const Order = require('../models/Order');
const Earning = require('../models/Earning');

// Public list of all cooks/suppliers (for customer view)
async function listAllCooks(req, res) {
  const cooks = await User.find({ role: 'cook' })
    .select('name kitchenName profileImage rating address phone isOnline isVerified')
    .sort({ rating: -1 });

  const cooksWithMeals = await Promise.all(
    cooks.map(async (cook) => {
      const mealCount = await Meal.countDocuments({ cook: cook._id, available: true });
      return {
        ...cook.toObject(),
        mealCount,
      };
    })
  );
  return sendSuccess(res, cooksWithMeals);
}

// Public cook profile (for customer view)
async function getCookProfile(req, res) {
  const cook = await User.findOne({ _id: req.params.id, role: 'cook' }).select('-password');
  if (!cook) return res.status(404).json({ success: false, message: 'Cook not found' });
  const meals = await Meal.find({ cook: cook.id, available: true });
  return sendSuccess(res, { cook, meals });
}

// Authenticated cook's own profile
async function getMyProfile(req, res) {
  const cook = await User.findById(req.user.id).select('-password');
  if (!cook) return res.status(404).json({ success: false, message: 'Cook profile not found' });
  return sendSuccess(res, cook);
}

// Update authenticated cook profile
async function updateMyProfile(req, res) {
  const allowedFields = ['name', 'phone', 'address', 'kitchenName', 'profileImage', 'isOnline'];
  const updateData = {};
  for (const field of allowedFields) {
    if (req.body[field] !== undefined) {
      updateData[field] = req.body[field];
    }
  }

  const cook = await User.findByIdAndUpdate(req.user.id, updateData, { new: true }).select('-password');
  if (!cook) return res.status(404).json({ success: false, message: 'Cook not found' });
  return sendSuccess(res, cook, 'Profile updated successfully');
}

// Cook Dashboard overview / statistics
async function getCookDashboard(req, res) {
  const cookId = req.user.id;

  const cook = await User.findById(cookId).select('name kitchenName profileImage isOnline rating');

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  const todayOrders = await Order.countDocuments({
    cook: cookId,
    createdAt: { $gte: startOfToday },
  });

  // Calculate revenue from completed or accepted orders
  const revenueAgg = await Order.aggregate([
    { $match: { cook: new User()._id.constructor(cookId), status: { $ne: 'Rejected' } } },
    { $group: { _id: null, total: { $sum: '$total' } } },
  ]);
  const totalRevenue = revenueAgg[0]?.total || 0;

  // Recent 5 orders for dashboard
  const recentOrders = await Order.find({ cook: cookId })
    .sort({ createdAt: -1 })
    .limit(5)
    .populate('customer', 'name phone')
    .populate('items.meal', 'name imageUrl price category');

  return sendSuccess(res, {
    cook: {
      name: cook?.name || 'Home Cook',
      kitchenName: cook?.kitchenName || 'My Kitchen',
      profileImage: cook?.profileImage || '',
      isOnline: cook?.isOnline ?? true,
      rating: cook?.rating || 4.8,
    },
    statistics: {
      todayOrders,
      totalRevenue,
      averageRating: cook?.rating || 4.8,
    },
    recentOrders,
  });
}

// Cook's meals list (GET /api/cooks/meals)
async function getCookMeals(req, res) {
  const cookId = req.user.id;
  const meals = await Meal.find({ cook: cookId }).sort({ createdAt: -1 });
  return sendSuccess(res, meals);
}

// Cook's orders list (GET /api/cook/orders)
async function getCookOrders(req, res) {
  const cookId = req.user.id;
  const filter = { cook: cookId };

  if (req.query.status) {
    filter.status = req.query.status;
  }

  const orders = await Order.find(filter)
    .sort({ createdAt: -1 })
    .populate('customer', 'name phone address')
    .populate('items.meal', 'name imageUrl price category');

  return sendSuccess(res, orders);
}

// Cook order details (GET /api/cook/orders/:id)
async function getCookOrderById(req, res) {
  const cookId = req.user.id;
  const order = await Order.findOne({ _id: req.params.id, cook: cookId })
    .populate('customer', 'name phone address')
    .populate('items.meal', 'name imageUrl price category');

  if (!order) {
    return res.status(404).json({ success: false, message: 'Order not found' });
  }

  return sendSuccess(res, order);
}

// Cook earnings summary and analytics (GET /api/cook/earnings)
async function getCookEarnings(req, res) {
  const cookId = req.user.id;
  const now = new Date();

  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const earnings = await Earning.find({ cookId }).sort({ date: -1 });
  const totalEarnings = earnings.reduce((sum, e) => sum + e.amount, 0);

  const todayEarnings = earnings
    .filter((e) => new Date(e.date) >= startOfToday)
    .reduce((sum, e) => sum + e.amount, 0);

  const weeklyEarnings = earnings
    .filter((e) => new Date(e.date) >= startOfWeek)
    .reduce((sum, e) => sum + e.amount, 0);

  const monthlyEarnings = earnings
    .filter((e) => new Date(e.date) >= startOfMonth)
    .reduce((sum, e) => sum + e.amount, 0);

  // Daily sales for the last 7 days
  const dailySales = [];
  const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  for (let i = 6; i >= 0; i--) {
    const day = new Date();
    day.setDate(now.getDate() - i);
    const dayStart = new Date(day.getFullYear(), day.getMonth(), day.getDate());
    const dayEnd = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1);

    const dayEarnings = earnings
      .filter((e) => new Date(e.date) >= dayStart && new Date(e.date) < dayEnd)
      .reduce((sum, e) => sum + e.amount, 0);

    const orderCount = await Order.countDocuments({
      cook: cookId,
      createdAt: { $gte: dayStart, $lt: dayEnd },
    });

    dailySales.push({
      day: daysOfWeek[day.getDay()],
      date: day.toISOString().slice(5, 10),
      sales: dayEarnings,
      orderCount,
    });
  }

  return sendSuccess(res, {
    totalEarnings,
    todayEarnings,
    weeklyEarnings,
    monthlyEarnings,
    dailySales,
    recentEarnings: earnings.slice(0, 10),
  });
}

module.exports = {
  listAllCooks,
  getCookProfile,
  getMyProfile,
  updateMyProfile,
  getCookDashboard,
  getCookSummary: getCookDashboard,
  getCookMeals,
  getCookOrders,
  getCookOrderById,
  getCookEarnings,
};
