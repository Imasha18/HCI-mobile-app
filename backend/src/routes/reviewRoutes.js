const express = require('express');
const { createReview, listMealReviews } = require('../controllers/reviewController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.post('/', authenticate, createReview);
router.get('/meal/:mealId', listMealReviews);
module.exports = router;
