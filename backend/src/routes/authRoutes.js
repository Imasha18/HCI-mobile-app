const express = require('express');
const { register, login, verifyEmail, googleLogin, me } = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validateMiddleware');
const { validateAuth, validateRegistration } = require('../validators/authValidator');

const router = express.Router();
router.post('/register', validateBody(validateRegistration), register);
router.post('/login', validateBody(validateAuth), login);
router.post('/verify-email', verifyEmail);
router.post('/google', googleLogin);
router.get('/me', authenticate, me);
module.exports = router;
