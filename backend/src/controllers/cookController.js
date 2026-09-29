const { sendSuccess } = require('../utils/apiResponse');
const User = require('../models/User');
const Meal = require('../models/Meal');

async function getCookProfile(req, res) {
  const cook = await User.findOne({ _id: req.params.id, role: 'cook' }).select('-password');
  if (!cook) return res.status(404).json({ success: false, message: 'Cook not found' });
  const meals = await Meal.find({ cook: cook.id, available: true });
  return sendSuccess(res, { cook, meals });
}

async function getCookSummary(req, res) {
  return sendSuccess(res, { userId: req.user.id, message: 'Cook workspace ready' });
}

module.exports = { getCookSummary, getCookProfile };
