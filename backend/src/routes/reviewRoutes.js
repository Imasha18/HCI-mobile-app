const express = require('express');
const { createReview } = require('../controllers/reviewController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.post('/', authenticate, createReview);
module.exports = router;
