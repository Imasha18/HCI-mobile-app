const express = require('express');
const { getRiderSummary } = require('../controllers/riderController');
const { authenticate } = require('../middleware/authMiddleware');
const { authorizeRoles } = require('../middleware/roleMiddleware');
const router = express.Router();
router.get('/summary', authenticate, authorizeRoles('rider'), getRiderSummary);
module.exports = router;
