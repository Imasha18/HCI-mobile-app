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

module.exports = { listNotifications, markNotificationAsRead, markAllAsRead };
