const Notification = require('../models/Notification');
const { sendSuccess } = require('../utils/apiResponse');

async function listNotifications(req, res) {
  return sendSuccess(res, await Notification.find({ user: req.user.id }).sort({ createdAt: -1 }));
}

module.exports = { listNotifications };
