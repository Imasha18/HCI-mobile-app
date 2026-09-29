const express = require('express');
const { createPayment } = require('../controllers/paymentController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.post('/', authenticate, createPayment);
router.post('/create', authenticate, createPayment);
module.exports = router;
