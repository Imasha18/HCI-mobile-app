const express = require('express');
const { getDeliverySummary } = require('../controllers/deliveryController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.get('/summary', authenticate, getDeliverySummary);
module.exports = router;
