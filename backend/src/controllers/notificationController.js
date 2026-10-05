const Notification = require('../models/Notification');
const { sendSuccess } = require('../utils/apiResponse');

async function listNotifications(req, res) {
  let notifications = await Notification.find({ user: req.user.id }).sort({ createdAt: -1 });

  // If user is cook and notifications are empty, seed default cook alerts
  if (!notifications.length && req.user.role === 'cook') {
    const defaults = [
      {
        user: req.user.id,
        title: 'New order received',
        body: 'Order #HB-8492 for Special Chicken Kottu was received.',
        read: false,
      },
      {
        user: req.user.id,
        title: 'Order accepted',
        body: 'You accepted order #HB-7721. Estimated cooking time: 25 min.',
        read: true,
      },
      {
        user: req.user.id,
        title: 'Customer cancelled order',
        body: 'Order #HB-6302 was cancelled by customer prior to preparation.',
        read: true,
      },
      {
        user: req.user.id,
        title: 'Payment completed',
        body: 'Payout of Rs. 14,250.00 was credited to your Commercial Bank account.',
        read: true,
      },
    ];
    notifications = await Notification.insertMany(defaults);
  }

  // If user is rider and notifications are empty, seed default rider alerts
  if (!notifications.length && req.user.role === 'rider') {
    const defaults = [
      {
        user: req.user.id,
        title: 'New delivery request',
        body: "Delivery available from Amma's Spice Kitchen (3.8 km away). Tap to view.",
        read: false,
      },
      {
        user: req.user.id,
        title: 'Delivery accepted',
        body: 'You accepted delivery for Order #HB-9142. Please proceed to kitchen.',
        read: false,
      },
      {
        user: req.user.id,
        title: 'Customer location updated',
        body: 'Nimal Jayasuriya updated drop notes: "Leave at security guard desk".',
        read: true,
      },
      {
        user: req.user.id,
        title: 'Delivery completed',
        body: 'Order #HB-8492 completed! Rs. 450.00 added to your daily earnings.',
        read: true,
      },
    ];
    notifications = await Notification.insertMany(defaults);
  }

  return sendSuccess(res, notifications);
}

async function markNotificationAsRead(req, res) {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, user: req.user.id },
    { read: true },
    { new: true }
  );
  if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });
  return sendSuccess(res, notification, 'Notification marked as read');
}

async function markAllAsRead(req, res) {
  await Notification.updateMany({ user: req.user.id }, { read: true });
  return sendSuccess(res, {}, 'All notifications marked as read');
}

async function deleteNotification(req, res) {
  const notification = await Notification.findOneAndDelete({ _id: req.params.id, user: req.user.id });
  if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });
  return sendSuccess(res, {}, 'Notification deleted successfully');
}

module.exports = { listNotifications, markNotificationAsRead, markAllAsRead, deleteNotification };
