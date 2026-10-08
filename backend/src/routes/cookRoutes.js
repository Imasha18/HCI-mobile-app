const express = require('express');
const {
  listAllCooks,
  getCookProfile,
  getMyProfile,
  updateMyProfile,
  getCookDashboard,
  getCookKitchen,
  updateCookKitchen,
  getCookBankDetails,
  updateCookBankDetails,
  getCookDocuments,
  updateCookDocuments,
  getCookSettings,
  updateCookSettings,
  getCookMeals,
  getCookOrders,
  getCookOrderById,
  getCookEarnings,
} = require('../controllers/cookController');
const {
  createMeal,
  updateMeal,
  deleteMeal,
  toggleAvailability,
  getMeal,
} = require('../controllers/mealController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const { upload } = require('../middleware/uploadMiddleware');

const router = express.Router();

// Specific routes first before /:id parameter
router.get('/profile', authenticate, authorizeRoles('cook'), getMyProfile);
router.put('/profile', authenticate, authorizeRoles('cook'), upload.single('profileImage'), updateMyProfile);
router.patch('/profile', authenticate, authorizeRoles('cook'), upload.single('profileImage'), updateMyProfile);

router.get('/dashboard', authenticate, authorizeRoles('cook'), getCookDashboard);
router.get('/summary', authenticate, authorizeRoles('cook'), getCookDashboard);

// Kitchen profile routes
router.get('/kitchen', authenticate, authorizeRoles('cook'), getCookKitchen);
router.put('/kitchen', authenticate, authorizeRoles('cook'), upload.single('image'), updateCookKitchen);
router.patch('/kitchen', authenticate, authorizeRoles('cook'), upload.single('image'), updateCookKitchen);

// Bank details routes
router.get('/bank-details', authenticate, authorizeRoles('cook'), getCookBankDetails);
router.put('/bank-details', authenticate, authorizeRoles('cook'), updateCookBankDetails);
router.patch('/bank-details', authenticate, authorizeRoles('cook'), updateCookBankDetails);

// Document verification routes
router.get('/documents', authenticate, authorizeRoles('cook'), getCookDocuments);
router.post('/documents', authenticate, authorizeRoles('cook'), upload.single('file'), updateCookDocuments);
router.put('/documents', authenticate, authorizeRoles('cook'), upload.single('file'), updateCookDocuments);

// Settings routes
router.get('/settings', authenticate, authorizeRoles('cook'), getCookSettings);
router.put('/settings', authenticate, authorizeRoles('cook'), updateCookSettings);
router.patch('/settings', authenticate, authorizeRoles('cook'), updateCookSettings);

// Cook meals CRUD under /api/cook/meals
router.get('/meals', authenticate, authorizeRoles('cook'), getCookMeals);
router.post('/meals', authenticate, authorizeRoles('cook'), upload.single('image'), createMeal);
router.get('/meals/:id', authenticate, authorizeRoles('cook'), getMeal);
router.put('/meals/:id', authenticate, authorizeRoles('cook'), upload.single('image'), updateMeal);
router.patch('/meals/:id', authenticate, authorizeRoles('cook'), upload.single('image'), updateMeal);
router.patch('/meals/:id/availability', authenticate, authorizeRoles('cook'), toggleAvailability);
router.delete('/meals/:id', authenticate, authorizeRoles('cook'), deleteMeal);

router.get('/orders', authenticate, authorizeRoles('cook'), getCookOrders);
router.get('/orders/:id', authenticate, authorizeRoles('cook'), getCookOrderById);
router.get('/earnings', authenticate, authorizeRoles('cook'), getCookEarnings);

// Public list of all cooks/suppliers
router.get('/', listAllCooks);

// Public profile by cook id
router.get('/:id', getCookProfile);

module.exports = router;
