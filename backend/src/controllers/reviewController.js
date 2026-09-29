const Review = require('../models/Review');
const { sendSuccess } = require('../utils/apiResponse');

async function createReview(req, res) {
  return sendSuccess(res, await Review.create({ ...req.body, customer: req.user.id }), 'Review created', 201);
}

async function listMealReviews(req, res) {
  return sendSuccess(res, await Review.find({ meal: req.params.mealId }).populate('customer', 'name').sort({ createdAt: -1 }));
}

module.exports = { createReview, listMealReviews };
