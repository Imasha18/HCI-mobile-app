const express = require('express');
const { getCookSummary, getCookProfile } = require('../controllers/cookController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('cook'), getCookSummary);
router.get('/:id', getCookProfile);
module.exports = router;
