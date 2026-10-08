const Review = require('../models/Review');
const Meal = require('../models/Meal');
const { sendSuccess } = require('../utils/apiResponse');
const { parsePagination, buildPaginationMeta } = require('../utils/pagination');

async function createReview(req, res) {
  const { meal, rating, comment } = req.body;
  if (!meal) return res.status(400).json({ success: false, message: 'Meal ID is required' });
  const numRating = Number(rating);
  if (isNaN(numRating) || numRating < 1 || numRating > 5) {
    return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5' });
  }

  const review = await Review.create({
    meal,
    rating: numRating,
    comment: comment ? String(comment).trim() : '',
    customer: req.user.id,
  });

  // Recalculate meal rating and review count
  try {
    const allReviews = await Review.find({ meal });
    const avg = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
    await Meal.findByIdAndUpdate(meal, {
      rating: Math.round(avg * 10) / 10,
      ratingCount: allReviews.length,
    });
  } catch (_) {}

  return sendSuccess(res, review, 'Review created', 201);
}

async function listMealReviews(req, res) {
  const filter = { meal: req.params.mealId };
  if (req.query.page || req.query.limit) {
    const { page, limit, skip } = parsePagination(req.query, 10);
    const total = await Review.countDocuments(filter);
    const reviews = await Review.find(filter)
      .populate('customer', 'name profileImage')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    return sendSuccess(res, reviews, 'Success', 200, buildPaginationMeta(page, limit, total, reviews.length));
  }
  return sendSuccess(res, await Review.find(filter).populate('customer', 'name profileImage').sort({ createdAt: -1 }));
}

module.exports = { createReview, listMealReviews };
