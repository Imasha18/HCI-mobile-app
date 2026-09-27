const express = require('express');
const { getCookSummary } = require('../controllers/cookController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('cook'), getCookSummary);
module.exports = router;
