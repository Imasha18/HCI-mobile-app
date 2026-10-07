const Review = require('../models/Review');
const { sendSuccess } = require('../utils/apiResponse');

const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

async function createReview(req, res) {
  return sendSuccess(res, await Review.create({ ...req.body, customer: req.user.id }), 'Review created', 201);
}

async function listMealReviews(req, res) {
  const filter = { meal: req.params.mealId };
  if (req.query.page || req.query.limit) {
    const { page, limit, skip } = parsePagination(req.query, 10);
    const total = await Review.countDocuments(filter);
    const reviews = await Review.find(filter).populate('customer', 'name').sort({ createdAt: -1 }).skip(skip).limit(limit);
    return sendSuccess(res, reviews, 'Success', 200, buildPaginationMeta(page, limit, total, reviews.length));
  }
  return sendSuccess(res, await Review.find(filter).populate('customer', 'name').sort({ createdAt: -1 }));
}

module.exports = { createReview, listMealReviews };
