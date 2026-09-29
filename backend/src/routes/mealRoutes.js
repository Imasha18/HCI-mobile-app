const express = require('express');
const { listMeals, searchMeals, getMeal, createMeal } = require('../controllers/mealController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();
router.get('/', listMeals);
router.get('/search', searchMeals);
router.get('/:id', getMeal);
router.post('/', authenticate, authorizeRoles('cook'), createMeal);
module.exports = router;
