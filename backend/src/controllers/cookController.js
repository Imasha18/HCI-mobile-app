const mongoose = require('mongoose');
const { sendSuccess } = require('../utils/apiResponse');
const User = require('../models/User');
const Kitchen = require('../models/Kitchen');
const Meal = require('../models/Meal');
const Order = require('../models/Order');
const Earning = require('../models/Earning');
const { uploadImage } = require('../services/imageService');

// Helper to mask account numbers (e.g. 1234567890 -> ****7890)
function maskAccountNumber(acc) {
  if (!acc || typeof acc !== 'string') return '';
  const trimmed = acc.trim();
  if (trimmed.length <= 4) return trimmed;
  const last4 = trimmed.slice(-4);
  return `****${last4}`;
}

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
  if (!mongoose.isValidObjectId(req.params.id)) {
    return res.status(404).json({ success: false, message: 'Cook not found' });
  }
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

  if (req.file) {
    const uploaded = await uploadImage(req.file, 'homebite/profiles');
    if (uploaded) updateData.profileImage = uploaded;
  }

  const cook = await User.findByIdAndUpdate(req.user.id, updateData, { new: true }).select('-password');
  if (!cook) return res.status(404).json({ success: false, message: 'Cook not found' });

  // Sync kitchenName, phone, address, isOnline to Kitchen model
  const kitchenUpdates = {};
  if (updateData.kitchenName) kitchenUpdates.kitchenName = updateData.kitchenName;
  if (updateData.phone) kitchenUpdates.phone = updateData.phone;
  if (updateData.address) kitchenUpdates.address = updateData.address;
  if (updateData.isOnline !== undefined) kitchenUpdates.isOnline = updateData.isOnline;
  if (Object.keys(kitchenUpdates).length > 0) {
    await Kitchen.findOneAndUpdate({ cookId: req.user.id }, kitchenUpdates);
  }

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

  const cookObjectId = mongoose.Types.ObjectId.isValid(cookId)
    ? new mongoose.Types.ObjectId(cookId)
    : cookId;

  // Calculate revenue from completed or accepted orders
  const revenueAgg = await Order.aggregate([
    { $match: { cook: cookObjectId, status: { $nin: ['Rejected', 'Cancelled'] } } },
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
      kitchenName: cook?.kitchenName || (cook?.name ? `${cook.name}'s Kitchen` : 'My Kitchen'),
      profileImage: cook?.profileImage || '',
      isOnline: cook?.isOnline ?? true,
      rating: cook?.rating ?? 5.0,
    },
    statistics: {
      todayOrders,
      totalRevenue,
      averageRating: cook?.rating ?? 5.0,
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
    .populate('rider', 'name phone vehicleDetails rating profileImage')
    .populate('items.meal', 'name imageUrl price category');

  return sendSuccess(res, orders);
}

// Cook order details (GET /api/cook/orders/:id)
async function getCookOrderById(req, res) {
  const cookId = req.user.id;
  const order = await Order.findOne({ _id: req.params.id, cook: cookId })
    .populate('customer', 'name phone address')
    .populate('rider', 'name phone vehicleDetails rating profileImage')
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

// Kitchen details (GET /api/cook/kitchen)
async function getCookKitchen(req, res) {
  let kitchen = await Kitchen.findOne({ cookId: req.user.id });
  const user = await User.findById(req.user.id);
  if (!kitchen) {
    kitchen = await Kitchen.create({
      cookId: req.user.id,
      kitchenName: user?.kitchenName || `${user?.name || 'Home Cook'}'s Kitchen`,
      address: user?.address || '',
      phone: user?.phone || '',
      isOnline: user?.isOnline ?? true,
    });
  }
  return sendSuccess(res, kitchen);
}

// Update kitchen details (PUT /api/cook/kitchen)
async function updateCookKitchen(req, res) {
  let kitchen = await Kitchen.findOne({ cookId: req.user.id });
  if (!kitchen) {
    const user = await User.findById(req.user.id);
    kitchen = new Kitchen({
      cookId: req.user.id,
      kitchenName: req.body.kitchenName || user?.kitchenName || 'My Kitchen',
    });
  }

  if (req.file) {
    const uploaded = await uploadImage(req.file, 'homebite/kitchens');
    if (uploaded) kitchen.image = uploaded;
  } else if (req.body.image) {
    kitchen.image = req.body.image;
  }

  if (req.body.bannerImage !== undefined) kitchen.bannerImage = req.body.bannerImage;
  if (req.body.kitchenName !== undefined && req.body.kitchenName.trim()) {
    kitchen.kitchenName = req.body.kitchenName.trim();
  }
  if (req.body.bio !== undefined) kitchen.bio = req.body.bio.trim();
  if (req.body.phone !== undefined) kitchen.phone = req.body.phone.trim();
  if (req.body.address !== undefined) kitchen.address = req.body.address.trim();
  if (req.body.openingHours !== undefined) kitchen.openingHours = req.body.openingHours.trim();
  if (req.body.isOnline !== undefined) kitchen.isOnline = Boolean(req.body.isOnline);
  if (req.body.cuisineTypes !== undefined) {
    kitchen.cuisineTypes = Array.isArray(req.body.cuisineTypes)
      ? req.body.cuisineTypes
      : String(req.body.cuisineTypes).split(',').map((s) => s.trim()).filter(Boolean);
  }

  await kitchen.save();

  // Sync to User record
  const userUpdates = {};
  if (kitchen.kitchenName) userUpdates.kitchenName = kitchen.kitchenName;
  if (kitchen.phone) userUpdates.phone = kitchen.phone;
  if (kitchen.address) userUpdates.address = kitchen.address;
  if (kitchen.isOnline !== undefined) userUpdates.isOnline = kitchen.isOnline;
  if (Object.keys(userUpdates).length > 0) {
    await User.findByIdAndUpdate(req.user.id, userUpdates);
  }

  return sendSuccess(res, kitchen, 'Kitchen profile updated successfully');
}

// Cook bank details (GET /api/cook/bank-details)
async function getCookBankDetails(req, res) {
  const user = await User.findById(req.user.id).select('bankDetails');
  const details = user?.bankDetails ? user.bankDetails.toObject() : {
    accountHolderName: '',
    bankName: '',
    branchName: '',
    accountNumber: '',
    isVerified: false,
  };
  return sendSuccess(res, {
    ...details,
    maskedAccountNumber: maskAccountNumber(details.accountNumber),
  });
}

// Update bank details (PUT /api/cook/bank-details)
async function updateCookBankDetails(req, res) {
  const { accountHolderName, bankName, branchName, accountNumber } = req.body;

  if (!accountHolderName || !accountHolderName.trim()) {
    return res.status(400).json({ success: false, message: 'Account holder name is required' });
  }
  if (!bankName || !bankName.trim()) {
    return res.status(400).json({ success: false, message: 'Bank name is required' });
  }
  if (!branchName || !branchName.trim()) {
    return res.status(400).json({ success: false, message: 'Branch name is required' });
  }
  if (!accountNumber || !accountNumber.trim()) {
    return res.status(400).json({ success: false, message: 'Account number is required' });
  }

  const cleanAccountNumber = accountNumber.trim().replace(/\s+/g, '');
  if (!/^\d{6,20}$/.test(cleanAccountNumber)) {
    return res.status(400).json({ success: false, message: 'Account number must contain 6 to 20 digits' });
  }

  const bankDetails = {
    accountHolderName: accountHolderName.trim(),
    bankName: bankName.trim(),
    branchName: branchName.trim(),
    accountNumber: cleanAccountNumber,
    isVerified: true,
  };

  const user = await User.findByIdAndUpdate(
    req.user.id,
    { bankDetails },
    { new: true }
  ).select('bankDetails');

  return sendSuccess(res, {
    ...user.bankDetails.toObject(),
    maskedAccountNumber: maskAccountNumber(user.bankDetails.accountNumber),
  }, 'Bank details saved successfully');
}

// Cook verification documents (GET /api/cook/documents)
async function getCookDocuments(req, res) {
  const user = await User.findById(req.user.id).select('cookDocuments');
  const docs = user?.cookDocuments || {
    nic: { type: 'nic', fileUrl: '', fileName: '', status: 'not_submitted' },
    phiCertificate: { type: 'phiCertificate', fileUrl: '', fileName: '', status: 'not_submitted' },
    foodHandlingCertificate: { type: 'foodHandlingCertificate', fileUrl: '', fileName: '', status: 'not_submitted' },
  };
  return sendSuccess(res, docs);
}

// Update cook documents (POST /api/cook/documents)
async function updateCookDocuments(req, res) {
  const { documentType, fileUrl, fileName } = req.body;
  const validTypes = ['nic', 'phiCertificate', 'foodHandlingCertificate'];

  if (!documentType || !validTypes.includes(documentType)) {
    return res.status(400).json({
      success: false,
      message: `Invalid document type. Must be one of: ${validTypes.join(', ')}`,
    });
  }

  let finalUrl = fileUrl || '';
  let finalName = fileName || `${documentType}.pdf`;

  if (req.file) {
    const uploaded = await uploadImage(req.file, 'homebite/documents');
    if (uploaded) {
      finalUrl = uploaded;
      finalName = req.file.originalname || req.file.filename;
    }
  }

  const user = await User.findById(req.user.id);
  const currentDocs = user.cookDocuments || {};

  currentDocs[documentType] = {
    type: documentType,
    fileUrl: finalUrl || currentDocs[documentType]?.fileUrl || 'https://homebite.com/docs/sample.pdf',
    fileName: finalName || currentDocs[documentType]?.fileName || `${documentType}.pdf`,
    status: 'pending',
    uploadedAt: new Date(),
    rejectionReason: null,
  };

  user.cookDocuments = currentDocs;
  user.markModified('cookDocuments');
  await user.save();

  return sendSuccess(res, user.cookDocuments, 'Document submitted for verification');
}

// Cook kitchen settings (GET /api/cook/settings)
async function getCookSettings(req, res) {
  const user = await User.findById(req.user.id).select('cookSettings');
  const settings = user?.cookSettings || {
    operatingHours: '11:00 AM - 10:00 PM',
    autoAcceptOrders: true,
    deliveryRadiusKm: 7.0,
    notifications: {
      orderAlerts: true,
      emailAlerts: true,
      smsAlerts: false,
    },
  };
  return sendSuccess(res, settings);
}

// Update settings (PUT /api/cook/settings)
async function updateCookSettings(req, res) {
  const { operatingHours, autoAcceptOrders, deliveryRadiusKm, notifications } = req.body;

  const user = await User.findById(req.user.id);
  const currentSettings = user.cookSettings || {};

  if (operatingHours !== undefined) {
    currentSettings.operatingHours = operatingHours;
    await Kitchen.findOneAndUpdate({ cookId: req.user.id }, { openingHours: operatingHours });
  }
  if (autoAcceptOrders !== undefined) currentSettings.autoAcceptOrders = Boolean(autoAcceptOrders);
  if (deliveryRadiusKm !== undefined) currentSettings.deliveryRadiusKm = Number(deliveryRadiusKm);
  if (notifications !== undefined) {
    currentSettings.notifications = {
      ...currentSettings.notifications,
      ...notifications,
    };
  }

  user.cookSettings = currentSettings;
  user.markModified('cookSettings');
  await user.save();

  return sendSuccess(res, user.cookSettings, 'Settings updated successfully');
}

module.exports = {
  listAllCooks,
  getCookProfile,
  getMyProfile,
  updateMyProfile,
  getCookDashboard,
  getCookSummary: getCookDashboard,
  getCookKitchen,
  updateCookKitchen,
  getCookBankDetails,
  updateCookBankDetails,
  getCookDocuments,
  updateCookDocuments,
  getCookSettings,
  updateCookSettings,
  getCookMeals,
  getCookOrders,
  getCookOrderById,
  getCookEarnings,
};
