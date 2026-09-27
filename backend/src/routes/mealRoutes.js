const express = require('express');
const { listMeals, getMeal, createMeal } = require('../controllers/mealController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');

const router = express.Router();
router.get('/', listMeals);
router.get('/:id', getMeal);
router.post('/', authenticate, authorizeRoles('cook'), createMeal);
module.exports = router;
