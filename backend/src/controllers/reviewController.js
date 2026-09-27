const Review = require('../models/Review');
const { sendSuccess } = require('../utils/apiResponse');

async function createReview(req, res) {
  return sendSuccess(res, await Review.create({ ...req.body, customer: req.user.id }), 'Review created', 201);
}

module.exports = { createReview };
