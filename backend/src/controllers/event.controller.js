const { validationResult } = require('express-validator');
const Event = require('../models/Event');
const User = require('../models/User');

// Handle validation errors
const handleValidationErrors = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array(),
    });
  }
  return null;
};

// Get all events (with filters and pagination)
exports.getAllEvents = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      category, 
      location, 
      dateFrom, 
      dateTo, 
      priceMin, 
      priceMax,
      isVirtual,
      status = 'active'
    } = req.query;

    const query = { status };
    
    if (category) query.category = category;
    if (isVirtual !== undefined) query.isVirtual = isVirtual === 'true';
    
    if (location) {
      query.$or = [
        { 'location.city': { $regex: location, $options: 'i' } },
        { 'location.country': { $regex: location, $options: 'i' } },
        { 'location.venue': { $regex: location, $options: 'i' } },
      ];
    }
    
    if (dateFrom || dateTo) {
      query.dateTime = {};
      if (dateFrom) query.dateTime.$gte = new Date(dateFrom);
      if (dateTo) query.dateTime.$lte = new Date(dateTo);
    }
    
    if (priceMin !== undefined || priceMax !== undefined) {
      query.price = {};
      if (priceMin !== undefined) query.price.$gte = parseFloat(priceMin);
      if (priceMax !== undefined) query.price.$lte = parseFloat(priceMax);
    }

    const events = await Event.find(query)
      .populate('organizer', 'name email company')
      .sort({ dateTime: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Event.countDocuments(query);

    // Add computed fields
    const eventsWithComputedFields = events.map(event => ({
      ...event.toObject(),
      availableSpots: event.availableSpots,
      isActive: event.isActive,
    }));

    res.json({
      success: true,
      data: eventsWithComputedFields,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching events',
      error: error.message,
    });
  }
};

// Get single event by ID
exports.getEventById = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('organizer', 'name email company jobTitle profileImage bio')
      .populate('attendees.user', 'name profileImage company jobTitle');
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    // Increment view count if user is viewing
    if (req.user) {
      event.analytics.views += 1;
      await event.save();
    }

    const eventData = {
      ...event.toObject(),
      availableSpots: event.availableSpots,
      isActive: event.isActive,
    };

    res.json({
      success: true,
      data: eventData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching event',
      error: error.message,
    });
  }
};

// Create new event
exports.createEvent = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const eventData = {
      ...req.body,
      organizer: req.user._id,
    };

    // Validate end time is after start time
    if (new Date(eventData.endDateTime) <= new Date(eventData.dateTime)) {
      return res.status(400).json({
        success: false,
        message: 'End time must be after start time',
      });
    }

    const event = await Event.create(eventData);
    
    // Add to user's organized events
    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { eventsOrganized: event._id }
    });

    const populatedEvent = await Event.findById(event._id)
      .populate('organizer', 'name email company');

    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      data: populatedEvent,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating event',
      error: error.message,
    });
  }
};

// Update event
exports.updateEvent = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const event = await Event.findById(req.params.id);
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    // Check if user is the organizer
    if (event.organizer.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this event',
      });
    }

    // Validate end time is after start time if both are being updated
    const endDateTime = req.body.endDateTime || event.endDateTime;
    const startDateTime = req.body.dateTime || event.dateTime;
    
    if (new Date(endDateTime) <= new Date(startDateTime)) {
      return res.status(400).json({
        success: false,
        message: 'End time must be after start time',
      });
    }

    const updatedEvent = await Event.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).populate('organizer', 'name email company');

    res.json({
      success: true,
      message: 'Event updated successfully',
      data: updatedEvent,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating event',
      error: error.message,
    });
  }
};

// Delete event
exports.deleteEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    // Check if user is the organizer
    if (event.organizer.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this event',
      });
    }

    // Remove event from all attendees' lists
    const attendeeIds = event.attendees.map(a => a.user);
    await User.updateMany(
      { _id: { $in: attendeeIds } },
      { $pull: { eventsAttending: event._id } }
    );

    // Remove event from organizer's list
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { eventsOrganized: event._id }
    });

    await Event.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Event deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting event',
      error: error.message,
    });
  }
};

// Register for event
exports.registerForEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    if (!event.settings.registrationOpen) {
      return res.status(400).json({
        success: false,
        message: 'Registration is closed for this event',
      });
    }

    // Check if user is already registered
    const existingAttendee = event.attendees.find(
      a => a.user.toString() === req.user._id.toString()
    );

    if (existingAttendee) {
      return res.status(400).json({
        success: false,
        message: 'Already registered for this event',
      });
    }

    // Register user
    await event.registerAttendee(req.user._id);
    
    // Add to user's attending events
    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { eventsAttending: event._id }
    });

    res.json({
      success: true,
      message: 'Successfully registered for event',
      data: {
        eventId: event._id,
        status: event.availableSpots > 0 ? 'registered' : 'waitlisted',
      },
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Unregister from event
exports.unregisterFromEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    // Check if user is registered
    const attendeeIndex = event.attendees.findIndex(
      a => a.user.toString() === req.user._id.toString()
    );

    if (attendeeIndex === -1) {
      return res.status(400).json({
        success: false,
        message: 'Not registered for this event',
      });
    }

    // Check cancellation policy
    if (event.settings.cancellationDeadline && 
        new Date() > new Date(event.settings.cancellationDeadline)) {
      return res.status(400).json({
        success: false,
        message: 'Cancellation deadline has passed',
      });
    }

    // Remove attendee
    event.attendees.splice(attendeeIndex, 1);
    await event.save();
    
    // Remove from user's attending events
    await User.findByIdAndUpdate(req.user._id, {
      $pull: { eventsAttending: event._id }
    });

    // Promote waitlisted user if available
    const waitlistedAttendee = event.attendees.find(a => a.status === 'waitlisted');
    if (waitlistedAttendee && event.availableSpots > 0) {
      waitlistedAttendee.status = 'registered';
      await event.save();
    }

    res.json({
      success: true,
      message: 'Successfully unregistered from event',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error unregistering from event',
      error: error.message,
    });
  }
};

// Check in to event
exports.checkInToEvent = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id);
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    await event.checkInAttendee(req.user._id);

    res.json({
      success: true,
      message: 'Successfully checked in to event',
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// Get events by category
exports.getEventsByCategory = async (req, res) => {
  try {
    const { category } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const events = await Event.find({ 
      category, 
      status: 'active' 
    })
      .populate('organizer', 'name email company')
      .sort({ dateTime: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Event.countDocuments({ category, status: 'active' });

    res.json({
      success: true,
      data: events,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching events by category',
      error: error.message,
    });
  }
};

// Search events
exports.searchEvents = async (req, res) => {
  try {
    const { q, page = 1, limit = 10 } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const searchQuery = {
      status: 'active',
      $or: [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
        { tags: { $in: [new RegExp(q, 'i')] } },
        { 'location.city': { $regex: q, $options: 'i' } },
        { 'location.venue': { $regex: q, $options: 'i' } },
      ],
    };

    const events = await Event.find(searchQuery)
      .populate('organizer', 'name email company')
      .sort({ dateTime: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Event.countDocuments(searchQuery);

    res.json({
      success: true,
      data: events,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error searching events',
      error: error.message,
    });
  }
};

// Get event attendees
exports.getEventAttendees = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('attendees.user', 'name profileImage company jobTitle bio')
      .select('title attendees settings');
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    // Filter attendees based on privacy settings
    let attendees = event.attendees;
    
    // If not the organizer, only show confirmed attendees for privacy
    if (!req.user || event.organizer.toString() !== req.user._id.toString()) {
      attendees = attendees.filter(a => a.status === 'registered' || a.status === 'attended');
    }

    res.json({
      success: true,
      data: {
        eventTitle: event.title,
        attendees,
        totalCount: attendees.length,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching event attendees',
      error: error.message,
    });
  }
};

// Get event sessions
exports.getEventSessions = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id).select('title sessions');
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    res.json({
      success: true,
      data: {
        eventTitle: event.title,
        sessions: event.sessions,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching event sessions',
      error: error.message,
    });
  }
};

// Get user's attending events
exports.getUserAttendingEvents = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate({
        path: 'eventsAttending',
        populate: { path: 'organizer', select: 'name email company' }
      });

    res.json({
      success: true,
      data: user.eventsAttending,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user attending events',
      error: error.message,
    });
  }
};

// Get user's organized events
exports.getUserOrganizedEvents = async (req, res) => {
  try {
    const events = await Event.find({ organizer: req.user._id })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user organized events',
      error: error.message,
    });
  }
};