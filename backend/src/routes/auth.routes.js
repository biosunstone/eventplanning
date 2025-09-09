const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Validation middleware
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('name').trim().isLength({ min: 2 }),
];

const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
];

const adminLoginValidation = [
  body('username').trim().isLength({ min: 3 }),
  body('password').notEmpty(),
];

// User Authentication Routes
router.post('/register', registerValidation, authController.registerUser);
router.post('/login', loginValidation, authController.loginUser);
router.post('/forgot-password', body('email').isEmail().normalizeEmail(), authController.forgotPassword);
router.post('/reset-password/:token', body('password').isLength({ min: 6 }), authController.resetPassword);

// Admin Authentication Routes
router.post('/admin/login', adminLoginValidation, authController.loginAdmin);
router.post('/admin/create-owner', authController.createOwnerAdmin); // One-time setup

// Protected Routes
router.get('/me', protect, authController.getMe);
router.put('/me', protect, authController.updateProfile);
router.post('/change-password', protect, authController.changePassword);
router.post('/logout', protect, authController.logout);

// Refresh token
router.post('/refresh', authController.refreshToken);

module.exports = router;