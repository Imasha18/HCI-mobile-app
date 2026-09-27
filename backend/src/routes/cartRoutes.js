const express = require('express');
const { getCart, updateCart } = require('../controllers/cartController');
const { authenticate } = require('../middleware/authMiddleware');
const router = express.Router();
router.use(authenticate);
router.route('/').get(getCart).put(updateCart);
module.exports = router;
