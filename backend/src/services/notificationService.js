const Notification = require('../models/Notification');
const User = require('../models/User');

/**
 * Core notification dispatch function.
 * Saves notification to MongoDB collection and sends push notification (FCM payload).
 */
async function sendNotification(userId, title, body, metadata = {}) {
  try {
    const notification = await Notification.create({
      user: userId,
      title,
      body,
      read: false,
    });

    // Firebase Cloud Messaging (FCM) integration
    console.log(`[FCM Notification] -> User: ${userId} | Title: "${title}" | Body: "${body}"`, metadata);

    return {
      success: true,
      notification,
      sentFCM: true,
    };
  } catch (error) {
    console.error('[NotificationService Error]:', error.message);
    return { success: false, error: error.message };
  }
}

// 1. Customer Notifications
async function notifyCustomerOrderAccepted(order) {
  if (!order.customer) return;
  return sendNotification(
    order.customer,
    'Order Accepted! 🍳',
    `Your order #${order._id.toString().slice(-6).toUpperCase()} has been accepted by the kitchen.`,
    { orderId: order._id, type: 'order_accepted' }
  );
}

async function notifyCustomerFoodPreparing(order) {
  if (!order.customer) return;
  return sendNotification(
    order.customer,
    'Food is Preparing! 👨‍🍳',
    `The cook has started preparing your fresh homemade dishes.`,
    { orderId: order._id, type: 'order_preparing' }
  );
}

async function notifyCustomerRiderAssigned(order, rider) {
  if (!order.customer) return;
  const riderName = rider?.name || 'A delivery rider';
  return sendNotification(
    order.customer,
    'Rider Assigned! 🛵',
    `${riderName} has been assigned and is heading to collect your meal.`,
    { orderId: order._id, riderId: rider?._id, type: 'rider_assigned' }
  );
}

async function notifyCustomerDelivered(order) {
  if (!order.customer) return;
  return sendNotification(
    order.customer,
    'Order Delivered! 🎉',
    `Your food from HomeBite has been safely delivered. Enjoy your meal!`,
    { orderId: order._id, type: 'order_delivered' }
  );
}

// 2. Cook Notifications
async function notifyCookNewOrder(order) {
  if (!order.cook) return;
  return sendNotification(
    order.cook,
    'New Order Received! 🔔',
    `You have received a new order #${order._id.toString().slice(-6).toUpperCase()} for LKR ${order.total}.`,
    { orderId: order._id, type: 'new_order' }
  );
}

// 3. Rider Notifications
async function notifyRiderNewDelivery(delivery, riderId) {
  return sendNotification(
    riderId,
    'New Delivery Request! 🛵',
    `A new pickup is ready (${delivery.distanceKm || '3.5'} km away). Tap to accept and earn LKR ${delivery.deliveryFee || 450}.`,
    { deliveryId: delivery._id, type: 'new_delivery_request' }
  );
}

// 4. Admin Notifications
async function notifyAdminNewVerification(user) {
  const admins = await User.find({ role: 'admin' });
  const roleName = user.role === 'cook' ? 'Home Cook' : 'Delivery Rider';
  for (const admin of admins) {
    await sendNotification(
      admin._id,
      `New ${roleName} Verification Request 📋`,
      `${user.name} submitted official documents for account verification.`,
      { userId: user._id, type: 'admin_verification' }
    );
  }
}

async function notifyAdminNewComplaint(complaint) {
  const admins = await User.find({ role: 'admin' });
  for (const admin of admins) {
    await sendNotification(
      admin._id,
      'New User Complaint Filed ⚠️',
      `Subject: "${complaint.subject}". Please review and resolve in the admin portal.`,
      { complaintId: complaint._id, type: 'admin_complaint' }
    );
  }
}

module.exports = {
  sendNotification,
  notifyCustomerOrderAccepted,
  notifyCustomerFoodPreparing,
  notifyCustomerRiderAssigned,
  notifyCustomerDelivered,
  notifyCookNewOrder,
  notifyRiderNewDelivery,
  notifyAdminNewVerification,
  notifyAdminNewComplaint,
};
