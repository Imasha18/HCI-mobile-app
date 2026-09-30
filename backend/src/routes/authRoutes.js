const express = require('express');
const { register, login, me } = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validateMiddleware');
const { validateAuth, validateRegistration } = require('../validators/authValidator');

const router = express.Router();
router.post('/register', validateBody(validateRegistration), register);
router.post('/login', validateBody(validateAuth), login);
router.get('/me', authenticate, me);
module.exports = router;
