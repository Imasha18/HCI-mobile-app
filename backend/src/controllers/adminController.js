const User = require('../models/User');
const Meal = require('../models/Meal');
const Order = require('../models/Order');
const Delivery = require('../models/Delivery');
const Complaint = require('../models/Complaint');
const Notification = require('../models/Notification');
const Earning = require('../models/Earning');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');
const {
  normalizeDocKey,
  normalizeVerificationDocuments,
  calculateRiderVerificationStatus,
} = require('./riderController');

// 1. Dashboard / Summary
async function getAdminSummary(req, res) {
  try {
    const [
      totalUsers,
      totalCustomers,
      totalCooks,
      totalRiders,
      totalOrders,
      ordersWithRevenue,
      pendingCooks,
      pendingRiders,
      openComplaints,
      recentUsers,
      recentOrdersList,
      recentComplaintsList,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ role: 'customer' }),
      User.countDocuments({ role: 'cook' }),
      User.countDocuments({ role: 'rider' }),
      Order.countDocuments(),
      Order.find({ paymentStatus: 'paid' }).select('total'),
      User.countDocuments({ role: 'cook', verificationStatus: 'pending' }),
      User.countDocuments({ role: 'rider', verificationStatus: 'pending' }),
      Complaint.countDocuments({ status: { $ne: 'resolved' } }),
      User.find().sort({ createdAt: -1 }).limit(5).select('name email role createdAt isVerified isBlocked'),
      Order.find().sort({ createdAt: -1 }).limit(5).populate('customer', 'name email').populate('cook', 'name kitchenName'),
      Complaint.find().sort({ createdAt: -1 }).limit(5).populate('user', 'name email role'),
    ]);

    const revenue = ordersWithRevenue.reduce((acc, curr) => acc + (curr.total || 0), 0);

    // Build unified recent activities
    const activities = [];
    for (const u of recentUsers) {
      activities.push({
        id: `user-${u._id}`,
        type: u.role === 'cook' ? 'cook_registration' : u.role === 'rider' ? 'rider_registration' : 'user_registration',
        title: `New ${u.role} joined: ${u.name}`,
        subtitle: u.email,
        timestamp: u.createdAt,
        status: u.isVerified ? 'verified' : 'pending',
      });
    }
    for (const o of recentOrdersList) {
      activities.push({
        id: `order-${o._id}`,
        type: 'recent_order',
        title: `Order #${o._id.toString().slice(-6).toUpperCase()}`,
        subtitle: `${o.customer?.name || 'Customer'} - LKR ${o.total}`,
        timestamp: o.createdAt,
        status: o.status || 'Order Received',
      });
    }
    for (const c of recentComplaintsList) {
      activities.push({
        id: `complaint-${c._id}`,
        type: 'complaint',
        title: `Complaint: ${c.subject}`,
        subtitle: `By ${c.user?.name || 'User'}`,
        timestamp: c.createdAt,
        status: c.status || 'open',
      });
    }

    // Sort activities by newest first
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    return sendSuccess(res, {
      totalUsers,
      totalCustomers,
      totalCooks,
      totalRiders,
      totalOrders,
      revenue,
      pendingVerifications: pendingCooks + pendingRiders,
      pendingCooks,
      pendingRiders,
      openComplaints,
      recentActivities: activities.slice(0, 10),
      recentOrders: recentOrdersList,
    }, 'Admin dashboard metrics retrieved');
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 2. Users Management
async function getUsers(req, res) {
  try {
    const { role } = req.query;
    const filter = role ? { role } : {};

    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await User.countDocuments(filter);
      const users = await User.find(filter).sort({ createdAt: -1 }).select('-password').skip(skip).limit(limit);
      const normalizedUsers = users.map((u) => {
        const obj = u.toObject();
        if (obj.role === 'rider') {
          obj.verificationDocuments = normalizeVerificationDocuments(obj.verificationDocuments);
        }
        return obj;
      });
      return sendSuccess(res, normalizedUsers, 'Success', 200, buildPaginationMeta(page, limit, total, users.length));
    }

    const users = await User.find(filter).sort({ createdAt: -1 }).select('-password');
    const normalizedUsers = users.map((u) => {
      const obj = u.toObject();
      if (obj.role === 'rider') {
        obj.verificationDocuments = normalizeVerificationDocuments(obj.verificationDocuments);
      }
      return obj;
    });
    return sendSuccess(res, normalizedUsers);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function getCustomers(req, res) {
  try {
    const filter = { role: 'customer' };

    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await User.countDocuments(filter);
      const customers = await User.find(filter).sort({ createdAt: -1 }).select('-password').skip(skip).limit(limit);
      const customersWithOrders = await Promise.all(
        customers.map(async (c) => {
          const orderCount = await Order.countDocuments({ customer: c._id });
          const userObj = c.toObject();
          userObj.orderCount = orderCount;
          return userObj;
        })
      );
      return sendSuccess(res, customersWithOrders, 'Success', 200, buildPaginationMeta(page, limit, total, customers.length));
    }

    const customers = await User.find(filter).sort({ createdAt: -1 }).select('-password');
    
    // Add order counts for each customer
    const customersWithOrders = await Promise.all(
      customers.map(async (c) => {
        const orderCount = await Order.countDocuments({ customer: c._id });
        const userObj = c.toObject();
        userObj.orderCount = orderCount;
        return userObj;
      })
    );
    return sendSuccess(res, customersWithOrders);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function getCooks(req, res) {
  try {
    const filter = { role: 'cook' };

    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await User.countDocuments(filter);
      const cooks = await User.find(filter).sort({ createdAt: -1 }).select('-password').skip(skip).limit(limit);
      return sendSuccess(res, cooks, 'Success', 200, buildPaginationMeta(page, limit, total, cooks.length));
    }

    const cooks = await User.find(filter).sort({ createdAt: -1 }).select('-password');
    return sendSuccess(res, cooks);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function getRiders(req, res) {
  try {
    const filter = { role: 'rider' };

    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await User.countDocuments(filter);
      const riders = await User.find(filter).sort({ createdAt: -1 }).select('-password').skip(skip).limit(limit);
      const normalizedRiders = riders.map((r) => {
        const obj = r.toObject();
        obj.verificationDocuments = normalizeVerificationDocuments(obj.verificationDocuments);
        return obj;
      });
      return sendSuccess(res, normalizedRiders, 'Success', 200, buildPaginationMeta(page, limit, total, riders.length));
    }

    const riders = await User.find(filter).sort({ createdAt: -1 }).select('-password');
    const normalizedRiders = riders.map((r) => {
      const obj = r.toObject();
      obj.verificationDocuments = normalizeVerificationDocuments(obj.verificationDocuments);
      return obj;
    });
    return sendSuccess(res, normalizedRiders);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function getRiderById(req, res) {
  try {
    const { id } = req.params;
    const rider = await User.findOne({ _id: id, role: 'rider' }).select('-password');
    if (!rider) return sendError(res, 'Rider not found', 404);

    const riderObj = rider.toObject();
    riderObj.verificationDocuments = normalizeVerificationDocuments(riderObj.verificationDocuments);
    return sendSuccess(res, riderObj, 'Rider details retrieved successfully');
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function getRiderDocuments(req, res) {
  try {
    const { id } = req.params;
    const rider = await User.findOne({ _id: id, role: 'rider' }).select('name email phone vehicleDetails verificationDocuments verificationStatus isVerified');
    if (!rider) return sendError(res, 'Rider not found', 404);

    const normalized = normalizeVerificationDocuments(rider.verificationDocuments);
    return sendSuccess(res, {
      riderId: rider._id,
      name: rider.name,
      email: rider.email,
      phone: rider.phone,
      vehicleDetails: rider.vehicleDetails,
      verificationStatus: rider.verificationStatus,
      isVerified: rider.isVerified,
      documents: normalized,
    }, 'Rider documents retrieved successfully');
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function blockUser(req, res) {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(id, { isBlocked: true }, { new: true }).select('-password');
    if (!user) return sendError(res, 'User not found', 404);
    return sendSuccess(res, user, 'User blocked successfully');
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function unblockUser(req, res) {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(id, { isBlocked: false }, { new: true }).select('-password');
    if (!user) return sendError(res, 'User not found', 404);
    return sendSuccess(res, user, 'User unblocked successfully');
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function deleteUser(req, res) {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndDelete(id);
    if (!user) return sendError(res, 'User not found', 404);
    return sendSuccess(res, { id }, 'User deleted successfully');
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 3. Verification Management
async function verifyCook(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body; // 'approved' or 'rejected'
    const isApproved = status === 'approved';

    const cook = await User.findOneAndUpdate(
      { _id: id, role: 'cook' },
      {
        isVerified: isApproved,
        verificationStatus: isApproved ? 'approved' : 'rejected',
      },
      { new: true }
    ).select('-password');

    if (!cook) return sendError(res, 'Cook not found', 404);

    // Create a notification for the cook
    await Notification.create({
      user: cook._id,
      title: isApproved ? 'Kitchen Verified!' : 'Verification Application Update',
      body: isApproved
        ? 'Congratulations! Your kitchen profile has been verified by the HomeBite admin team.'
        : 'Your kitchen verification request was reviewed and could not be approved at this time.',
    });

    return sendSuccess(res, cook, `Cook ${status} successfully`);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function verifyRider(req, res) {
  try {
    const { id } = req.params;
    const rawKey = req.params.documentKey || req.body.documentKey || req.body.key;
    const documentKey = normalizeDocKey(rawKey);
    const { status, reason } = req.body; // 'approved' or 'rejected'

    if (!['approved', 'rejected'].includes(status)) {
      return sendError(res, 'Status must be approved or rejected', 400);
    }
    const isApproved = status === 'approved';

    if (!isApproved && (!reason || !reason.trim())) {
      return sendError(res, 'Please provide a reason for rejecting the verification request.', 400);
    }

    const rider = await User.findOne({ _id: id, role: 'rider' });
    if (!rider) return sendError(res, 'Rider not found', 404);

    const normalizedDocs = normalizeVerificationDocuments(rider.verificationDocuments);
    const adminId = req.user ? req.user.id : null;

    if (documentKey && normalizedDocs[documentKey]) {
      // Individual document decision
      if (isApproved) {
        normalizedDocs[documentKey].status = 'approved';
        normalizedDocs[documentKey].rejectionReason = null;
        normalizedDocs[documentKey].approvedAt = new Date();
        normalizedDocs[documentKey].approvedBy = adminId;
      } else {
        normalizedDocs[documentKey].status = 'rejected';
        normalizedDocs[documentKey].rejectionReason = reason.trim();
        normalizedDocs[documentKey].approvedAt = null;
        normalizedDocs[documentKey].approvedBy = null;
      }
    } else {
      // Bulk rider documents decision
      const standardKeys = ['nic', 'drivingLicense', 'vehicleDocument', 'insurance'];
      if (isApproved) {
        for (const k of standardKeys) {
          if (normalizedDocs[k].fileUrl) {
            normalizedDocs[k].status = 'approved';
            normalizedDocs[k].rejectionReason = null;
            normalizedDocs[k].approvedAt = new Date();
            normalizedDocs[k].approvedBy = adminId;
          }
        }
      } else {
        const rejectionReason = reason.trim();
        for (const k of standardKeys) {
          if (normalizedDocs[k].fileUrl && normalizedDocs[k].status !== 'approved') {
            normalizedDocs[k].status = 'rejected';
            normalizedDocs[k].rejectionReason = rejectionReason;
            normalizedDocs[k].approvedAt = null;
            normalizedDocs[k].approvedBy = null;
          }
        }
      }
    }

    // Recalculate overall rider verification status from documents
    const { verificationStatus, isVerified } = calculateRiderVerificationStatus(normalizedDocs);

    rider.verificationDocuments = normalizedDocs;
    rider.verificationStatus = verificationStatus;
    rider.isVerified = isVerified;
    rider.markModified('verificationDocuments');
    await rider.save();

    // Create a notification for the rider
    const title = documentKey
      ? `Document Update: ${documentKey} ${isApproved ? 'Approved' : 'Needs Attention'}`
      : (isApproved ? 'Rider Profile Verified!' : 'Verification Application Needs Attention');

    const body = isApproved
      ? (documentKey
          ? `Your ${documentKey} document has been approved by admin.`
          : 'Congratulations! All your delivery partner documents have been approved.')
      : (documentKey
          ? `Your ${documentKey} document was rejected: ${reason.trim()}`
          : `Your verification documents require attention: ${reason.trim()}`);

    await Notification.create({
      user: rider._id,
      title,
      body,
    }).catch(() => {});

    const publicData = await User.findById(rider._id).select('-password');
    const riderObj = publicData.toObject();
    riderObj.verificationDocuments = normalizeVerificationDocuments(riderObj.verificationDocuments);

    return sendSuccess(res, riderObj, `Rider verification ${status} successfully`);
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 4. Meal Monitoring
async function getMeals(req, res) {
  try {
    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await Meal.countDocuments();
      const meals = await Meal.find().populate('cook', 'name kitchenName email phone address').sort({ createdAt: -1 }).skip(skip).limit(limit);
      return sendSuccess(res, meals, 'Success', 200, buildPaginationMeta(page, limit, total, meals.length));
    }
    const meals = await Meal.find().populate('cook', 'name kitchenName email phone address').sort({ createdAt: -1 });
    return sendSuccess(res, meals);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function deleteMeal(req, res) {
  try {
    const { id } = req.params;
    const meal = await Meal.findByIdAndDelete(id);
    if (!meal) return sendError(res, 'Meal not found', 404);
    return sendSuccess(res, { id }, 'Meal deleted by administration');
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 5. Order Monitoring
async function getOrders(req, res) {
  try {
    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await Order.countDocuments();
      const orders = await Order.find()
        .populate('customer', 'name email phone address')
        .populate('cook', 'name kitchenName phone address')
        .populate('rider', 'name phone vehicleDetails')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);
      return sendSuccess(res, orders, 'Success', 200, buildPaginationMeta(page, limit, total, orders.length));
    }
    const orders = await Order.find()
      .populate('customer', 'name email phone address')
      .populate('cook', 'name kitchenName phone address')
      .populate('rider', 'name phone vehicleDetails')
      .sort({ createdAt: -1 });
    return sendSuccess(res, orders);
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 6. Complaint Management
async function getComplaints(req, res) {
  try {
    if (req.query.page || req.query.limit) {
      const { page, limit, skip } = parsePagination(req.query, 15);
      const total = await Complaint.countDocuments();
      const complaints = await Complaint.find()
        .populate('user', 'name email role phone')
        .populate({
          path: 'order',
          populate: [
            { path: 'customer', select: 'name email' },
            { path: 'cook', select: 'name kitchenName' },
          ],
        })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);
      return sendSuccess(res, complaints, 'Success', 200, buildPaginationMeta(page, limit, total, complaints.length));
    }
    const complaints = await Complaint.find()
      .populate('user', 'name email role phone')
      .populate({
        path: 'order',
        populate: [
          { path: 'customer', select: 'name email' },
          { path: 'cook', select: 'name kitchenName' },
        ],
      })
      .sort({ createdAt: -1 });
    return sendSuccess(res, complaints);
  } catch (error) {
    return sendError(res, error.message);
  }
}

async function updateComplaint(req, res) {
  try {
    const { id } = req.params;
    const { status, adminResponse } = req.body; // 'resolved' or 'rejected'
    const complaint = await Complaint.findByIdAndUpdate(
      id,
      {
        status: status || 'resolved',
        ...(adminResponse ? { adminResponse } : {}),
      },
      { new: true }
    ).populate('user', 'name email');

    if (!complaint) return sendError(res, 'Complaint not found', 404);

    // Notify user
    await Notification.create({
      user: complaint.user._id,
      title: `Complaint ${status === 'resolved' ? 'Resolved' : 'Updated'}`,
      body: adminResponse || `Your complaint "${complaint.subject}" has been updated to ${status}.`,
    });

    return sendSuccess(res, complaint, `Complaint marked as ${status}`);
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 7. Reports
async function getReports(req, res) {
  try {
    const [orders, cooks, riders, users] = await Promise.all([
      Order.find({ paymentStatus: 'paid' }).populate('cook', 'name kitchenName').populate('rider', 'name'),
      User.find({ role: 'cook' }),
      User.find({ role: 'rider' }),
      User.find(),
    ]);

    const totalSales = orders.reduce((sum, o) => sum + (o.total || 0), 0);
    const totalOrders = orders.length;

    // Cook performance
    const cookPerformance = cooks.map((c) => {
      const cookOrders = orders.filter((o) => o.cook && o.cook._id.toString() === c._id.toString());
      const cookRevenue = cookOrders.reduce((sum, o) => sum + (o.total || 0), 0);
      return {
        id: c._id,
        name: c.name,
        kitchenName: c.kitchenName || c.name,
        totalOrders: cookOrders.length,
        revenue: cookRevenue,
        rating: c.rating || 4.8,
      };
    });

    // Rider performance
    const riderPerformance = riders.map((r) => {
      const riderOrders = orders.filter((o) => o.rider && o.rider._id.toString() === r._id.toString());
      return {
        id: r._id,
        name: r.name,
        deliveriesCompleted: riderOrders.length,
        rating: r.rating || 4.9,
      };
    });

    return sendSuccess(res, {
      salesReport: {
        totalSales,
        totalOrders,
        averageOrderValue: totalOrders ? Math.round(totalSales / totalOrders) : 0,
      },
      orderReport: {
        totalOrders,
        completedOrders: orders.filter((o) => o.status === 'Delivered').length,
        pendingOrders: orders.filter((o) => o.status !== 'Delivered').length,
      },
      userReport: {
        total: users.length,
        customers: users.filter((u) => u.role === 'customer').length,
        cooks: cooks.length,
        riders: riders.length,
      },
      cookPerformance,
      riderPerformance,
    });
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 8. Statistics
async function getStatistics(req, res) {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [dailyOrdersCount, allOrders, popularMeals, activeUsersCount] = await Promise.all([
      Order.countDocuments({ createdAt: { $gte: today } }),
      Order.find({ paymentStatus: 'paid' }),
      Meal.find().sort({ rating: -1 }).limit(6).populate('cook', 'name kitchenName'),
      User.countDocuments({ isOnline: true }),
    ]);

    const monthlyRevenue = allOrders.reduce((sum, o) => sum + (o.total || 0), 0);

    // Revenue graph (Last 7 days mock aggregated data)
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const revenueGraph = days.map((day, idx) => ({
      day,
      amount: Math.round(monthlyRevenue * (0.08 + (idx * 0.03))),
    }));

    const orderGraph = days.map((day, idx) => ({
      day,
      orders: Math.max(2, Math.round(allOrders.length * (0.1 + (idx * 0.02)))),
    }));

    return sendSuccess(res, {
      dailyOrders: dailyOrdersCount || 3,
      monthlyRevenue,
      activeUsers: activeUsersCount || 8,
      popularMeals,
      revenueGraph,
      orderGraph,
    });
  } catch (error) {
    return sendError(res, error.message);
  }
}

// 9. Notifications for Admin
async function getAdminNotifications(req, res) {
  try {
    const [pendingCooks, pendingRiders, pendingComplaints, recentOrders] = await Promise.all([
      User.find({ role: 'cook', verificationStatus: 'pending' }),
      User.find({ role: 'rider', verificationStatus: 'pending' }),
      Complaint.find({ status: { $ne: 'resolved' } }).populate('user', 'name role'),
      Order.find().sort({ createdAt: -1 }).limit(3),
    ]);

    const notifications = [];

    for (const c of pendingCooks) {
      notifications.push({
        id: `notif-cook-${c._id}`,
        title: 'New Cook Registration',
        body: `${c.name} applied for "${c.kitchenName || 'Kitchen'}" verification.`,
        type: 'verification',
        time: c.createdAt,
        read: false,
      });
    }

    for (const r of pendingRiders) {
      notifications.push({
        id: `notif-rider-${r._id}`,
        title: 'New Rider Registration',
        body: `${r.name} uploaded driving documents for verification.`,
        type: 'verification',
        time: r.createdAt,
        read: false,
      });
    }

    for (const cmp of pendingComplaints) {
      notifications.push({
        id: `notif-cmp-${cmp._id}`,
        title: 'New Complaint Received',
        body: `Complaint: "${cmp.subject}" submitted by ${cmp.user?.name || 'User'}.`,
        type: 'complaint',
        time: cmp.createdAt,
        read: false,
      });
    }

    for (const ord of recentOrders) {
      notifications.push({
        id: `notif-ord-${ord._id}`,
        title: 'Order Activity Alert',
        body: `Order #${ord._id.toString().slice(-6).toUpperCase()} updated to status: ${ord.status}.`,
        type: 'order',
        time: ord.createdAt,
        read: true,
      });
    }

    return sendSuccess(res, notifications);
  } catch (error) {
    return sendError(res, error.message);
  }
}

module.exports = {
  getAdminSummary,
  getUsers,
  getCustomers,
  getCooks,
  getRiders,
  getRiderById,
  getRiderDocuments,
  blockUser,
  unblockUser,
  deleteUser,
  verifyCook,
  verifyRider,
  getMeals,
  deleteMeal,
  getOrders,
  getComplaints,
  updateComplaint,
  getReports,
  getStatistics,
  getAdminNotifications,
};
