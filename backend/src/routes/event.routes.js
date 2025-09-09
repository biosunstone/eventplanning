const express = require('express');
const { body } = require('express-validator');
const eventController = require('../controllers/event.controller');
const { protect, userOnly, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Public routes (no authentication required)
router.get('/', optionalAuth, eventController.getAllEvents);
router.get('/:id', optionalAuth, eventController.getEventById);
router.get('/category/:category', optionalAuth, eventController.getEventsByCategory);
router.get('/search', optionalAuth, eventController.searchEvents);

// Protected routes (user authentication required)
router.use(protect);

// Event management
router.post('/', 
  userOnly,
  [
    body('title').trim().isLength({ min: 3, max: 200 }),
    body('description').trim().isLength({ min: 10, max: 2000 }),
    body('dateTime').isISO8601().toDate(),
    body('endDateTime').isISO8601().toDate(),
    body('location.venue').trim().notEmpty(),
    body('location.address').trim().notEmpty(),
    body('location.city').trim().notEmpty(),
    body('location.country').trim().notEmpty(),
    body('capacity').isInt({ min: 1 }),
    body('price').isFloat({ min: 0 }),
    body('category').isIn(['conference', 'workshop', 'networking', 'seminar', 'social', 'other']),
  ],
  eventController.createEvent
);

router.put('/:id',
  userOnly,
  [
    body('title').optional().trim().isLength({ min: 3, max: 200 }),
    body('description').optional().trim().isLength({ min: 10, max: 2000 }),
    body('dateTime').optional().isISO8601().toDate(),
    body('endDateTime').optional().isISO8601().toDate(),
    body('capacity').optional().isInt({ min: 1 }),
    body('price').optional().isFloat({ min: 0 }),
  ],
  eventController.updateEvent
);

router.delete('/:id', userOnly, eventController.deleteEvent);

// Event interactions
router.post('/:id/register', userOnly, eventController.registerForEvent);
router.post('/:id/unregister', userOnly, eventController.unregisterFromEvent);
router.post('/:id/checkin', userOnly, eventController.checkInToEvent);

// Event details
router.get('/:id/attendees', eventController.getEventAttendees);
router.get('/:id/sessions', eventController.getEventSessions);

// User's events
router.get('/user/attending', userOnly, eventController.getUserAttendingEvents);
router.get('/user/organized', userOnly, eventController.getUserOrganizedEvents);

module.exports = router;