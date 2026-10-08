const express = require('express');
const {
  getRiderProfile,
  updateRiderProfile,
  uploadDocument,
  uploadOrSaveRiderDocument,
  submitVerification,
  getRiderDashboard,
  getRiderDeliveries,
  getRiderEarnings,
  updateRiderLocation,
} = require('../controllers/riderController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const { upload } = require('../middleware/uploadMiddleware');

const router = express.Router();

// All rider routes require rider role
router.use(authenticate, authorizeRoles('rider'));

router.get('/profile', getRiderProfile);
router.get('/me', getRiderProfile);
router.put('/profile', updateRiderProfile);
router.patch('/profile', updateRiderProfile);

// Document & Verification
router.post('/documents/upload', upload.single('file'), uploadOrSaveRiderDocument);
router.post('/documents', upload.single('file'), uploadOrSaveRiderDocument);
router.patch('/documents/:type', upload.single('file'), uploadOrSaveRiderDocument);
router.post('/documents/:type', upload.single('file'), uploadOrSaveRiderDocument);
router.post('/verification/submit', submitVerification);
router.post('/verification', submitVerification);
router.get('/verification', getRiderProfile);

router.get('/dashboard', getRiderDashboard);
router.get('/summary', getRiderDashboard);
router.get('/deliveries', getRiderDeliveries);
router.get('/earnings', getRiderEarnings);
router.patch('/location', updateRiderLocation);

module.exports = router;
