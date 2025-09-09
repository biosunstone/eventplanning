const express = require('express');
const { body } = require('express-validator');
const userController = require('../controllers/user.controller');
const { protect, userOnly } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(protect);
router.use(userOnly);

// Profile management
router.get('/profile', userController.getProfile);
router.put('/profile', 
  [
    body('name').optional().trim().isLength({ min: 2 }),
    body('company').optional().trim(),
    body('jobTitle').optional().trim(),
    body('bio').optional().trim().isLength({ max: 500 }),
    body('phone').optional().trim(),
  ],
  userController.updateProfile
);

// Social features
router.get('/connections', userController.getConnections);
router.post('/connections/send/:userId', userController.sendConnectionRequest);
router.post('/connections/accept/:userId', userController.acceptConnectionRequest);
router.post('/connections/reject/:userId', userController.rejectConnectionRequest);
router.delete('/connections/:userId', userController.removeConnection);

// Search and discovery
router.get('/search', userController.searchUsers);
router.get('/suggestions', userController.getUserSuggestions);

// Networking
router.get('/nearby', userController.getNearbyUsers);
router.get('/:userId/public-profile', userController.getPublicProfile);

module.exports = router;