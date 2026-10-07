const express = require('express');
const { register, registerCook, registerRider, login, verifyEmail, googleLogin, requestPasswordReset, resetPassword, me } = require('../controllers/authController');
const { authenticate } = require('../middleware/authMiddleware');
const { validateBody } = require('../middleware/validateMiddleware');
const { validateAuth, validateRegistration, validatePasswordReset } = require('../validators/authValidator');

const router = express.Router();
router.post('/register', validateBody(validateRegistration), register);
router.post('/register-cook', registerCook);
router.post('/register/cook', registerCook);
router.post('/register-rider', registerRider);
router.post('/register/rider', registerRider);
router.post('/login', validateBody(validateAuth), login);
router.post('/verify-email', verifyEmail);
router.post('/google', googleLogin);
router.post('/forgot-password', requestPasswordReset);
router.post('/reset-password', validateBody(validatePasswordReset), resetPassword);
router.get('/me', authenticate, me);
module.exports = router;
