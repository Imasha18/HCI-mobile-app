const User = require('../models/User');
const Delivery = require('../models/Delivery');
const Earning = require('../models/Earning');
const Location = require('../models/Location');
const { sendSuccess } = require('../utils/apiResponse');

// GET /api/rider/profile
async function getRiderProfile(req, res) {
  const rider = await User.findById(req.user.id).select('-password');
  if (!rider) return res.status(404).json({ success: false, message: 'Rider not found' });
  return sendSuccess(res, rider);
}

// PUT /api/rider/profile
async function updateRiderProfile(req, res) {
  const allowed = ['name', 'phone', 'address', 'profileImage', 'vehicleDetails', 'isOnline'];
  const updateData = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      updateData[key] = req.body[key];
    }
  }

  const rider = await User.findByIdAndUpdate(req.user.id, updateData, { new: true }).select('-password');
  if (!rider) return res.status(404).json({ success: false, message: 'Rider not found' });
  return sendSuccess(res, rider, 'Profile updated successfully');
}

// GET /api/rider/dashboard
async function getRiderDashboard(req, res) {
  const riderId = req.user.id;
  const rider = await User.findById(riderId).select('name email phone address profileImage isOnline rating vehicleDetails');

  const startOfToday = new Date();
  startOfToday.setHours(0, 0, 0, 0);

  // Today's completed deliveries
  const todayDeliveriesDocs = await Delivery.find({
    rider: riderId,
    status: 'DELIVERED',
    updatedAt: { $gte: startOfToday },
  });

  const todayDeliveries = todayDeliveriesDocs.length;
  const distanceTravelled = todayDeliveriesDocs.reduce((sum, d) => sum + (d.distanceKm || 0), 0);

  // Today's earnings
  const todayEarningsDocs = await Earning.find({
    riderId,
    date: { $gte: startOfToday },
  });
  const todayEarnings = todayEarningsDocs.reduce((sum, e) => sum + (e.amount || 0), 0);

  // Current active delivery (ACCEPTED, PICKED_UP, or IN_TRANSIT)
  const currentDelivery = await Delivery.findOne({
    rider: riderId,
    status: { $in: ['ACCEPTED', 'PICKED_UP', 'IN_TRANSIT'] },
  })
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address profileImage')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, {
    rider: {
      id: rider?._id || riderId,
      _id: rider?._id || riderId,
      name: rider?.name || 'HomeBite Rider',
      email: rider?.email || '',
      phone: rider?.phone || '',
      address: rider?.address || '',
      profileImage: rider?.profileImage || '',
      isOnline: rider?.isOnline ?? true,
      rating: rider?.rating || 5.0,
      vehicleDetails: {
        type: rider?.vehicleDetails?.type || 'Motorbike',
        model: rider?.vehicleDetails?.model || '',
        plateNumber: rider?.vehicleDetails?.plateNumber || '',
      },
    },
    statistics: {
      todayDeliveries,
      todayEarnings,
      rating: rider?.rating || 5.0,
      distanceTravelled: Number(distanceTravelled.toFixed(1)),
    },
    currentDelivery,
  });
}

const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

// GET /api/rider/deliveries (History)
async function getRiderDeliveries(req, res) {
  const riderId = req.user.id;
  const filter = { rider: riderId };
  if (req.query.status) {
    filter.status = req.query.status;
  }

  if (req.query.page || req.query.limit) {
    const { page, limit, skip } = parsePagination(req.query, 10);
    const total = await Delivery.countDocuments(filter);
    const deliveries = await Delivery.find(filter)
      .sort({ createdAt: -1 })
      .populate('orderId')
      .populate('cookId', 'name kitchenName phone address')
      .populate('customerId', 'name phone address')
      .skip(skip)
      .limit(limit);
    return sendSuccess(res, deliveries, 'Success', 200, buildPaginationMeta(page, limit, total, deliveries.length));
  }

  const deliveries = await Delivery.find(filter)
    .sort({ createdAt: -1 })
    .populate('orderId')
    .populate('cookId', 'name kitchenName phone address')
    .populate('customerId', 'name phone address');

  return sendSuccess(res, deliveries);
}

// GET /api/rider/earnings
async function getRiderEarnings(req, res) {
  const riderId = req.user.id;
  const now = new Date();

  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

  const earnings = await Earning.find({ riderId }).sort({ date: -1 });
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

  // Daily deliveries graph breakdown (past 7 days)
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const dailyBreakdown = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const dayEnd = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);

    const dayEarnings = earnings
      .filter((e) => new Date(e.date) >= dayStart && new Date(e.date) < dayEnd)
      .reduce((sum, e) => sum + e.amount, 0);

    const deliveryCount = await Delivery.countDocuments({
      rider: riderId,
      status: 'DELIVERED',
      updatedAt: { $gte: dayStart, $lt: dayEnd },
    });

    dailyBreakdown.push({
      day: days[d.getDay()],
      date: d.toISOString().split('T')[0],
      amount: dayEarnings,
      deliveries: deliveryCount,
    });
  }

  return sendSuccess(res, {
    totalEarnings,
    todayEarnings,
    weeklyEarnings,
    monthlyEarnings,
    dailyBreakdown,
  });
}

// PATCH /api/rider/location
async function updateRiderLocation(req, res) {
  const { latitude, longitude } = req.body;
  if (latitude === undefined || longitude === undefined) {
    return res.status(400).json({ success: false, message: 'Latitude and longitude are required' });
  }

  const loc = await Location.create({
    riderId: req.user.id,
    latitude: Number(latitude),
    longitude: Number(longitude),
    timestamp: new Date(),
  });

  return sendSuccess(res, loc, 'Location updated successfully');
}

module.exports = {
  getRiderProfile,
  updateRiderProfile,
  getRiderDashboard,
  getRiderDeliveries,
  getRiderEarnings,
  updateRiderLocation,
};
