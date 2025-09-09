const express = require('express');
const analyticsController = require('../controllers/analytics.controller');
const { protect, userOnly } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication
router.use(protect);
router.use(userOnly);

// User analytics
router.get('/events/attended', analyticsController.getUserEventAnalytics);
router.get('/connections/growth', analyticsController.getConnectionGrowth);
router.get('/engagement', analyticsController.getUserEngagement);

// Event organizer analytics
router.get('/events/:eventId/analytics', analyticsController.getEventAnalytics);
router.get('/events/organized/summary', analyticsController.getOrganizerSummary);

module.exports = router;