const express = require('express');
const {
  listMeals,
  searchMeals,
  getMeal,
  createMeal,
  updateMeal,
  deleteMeal,
  toggleAvailability,
} = require('../controllers/mealController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const { upload } = require('../middleware/uploadMiddleware');

const router = express.Router();

router.get('/', listMeals);
router.get('/search', searchMeals);
router.get('/:id', getMeal);

// Cook endpoints
router.post('/', authenticate, authorizeRoles('cook'), upload.single('image'), createMeal);
router.put('/:id', authenticate, authorizeRoles('cook'), upload.single('image'), updateMeal);
router.patch('/:id/availability', authenticate, authorizeRoles('cook'), toggleAvailability);
router.delete('/:id', authenticate, authorizeRoles('cook'), deleteMeal);

module.exports = router;
