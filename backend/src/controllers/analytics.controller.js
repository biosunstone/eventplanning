const User = require('../models/User');
const Event = require('../models/Event');

// Get user event analytics
exports.getUserEventAnalytics = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('eventsAttending', 'title dateTime category location.city status price');

    const analytics = {
      totalEventsAttended: user.eventsAttending.length,
      eventsByCategory: {},
      eventsByMonth: {},
      totalSpent: 0,
      upcomingEvents: 0,
    };

    const currentDate = new Date();

    user.eventsAttending.forEach(event => {
      // Category breakdown
      analytics.eventsByCategory[event.category] = 
        (analytics.eventsByCategory[event.category] || 0) + 1;

      // Monthly breakdown
      const month = event.dateTime.toLocaleString('default', { month: 'long', year: 'numeric' });
      analytics.eventsByMonth[month] = (analytics.eventsByMonth[month] || 0) + 1;

      // Total spent
      analytics.totalSpent += event.price || 0;

      // Upcoming events
      if (event.dateTime > currentDate && event.status === 'active') {
        analytics.upcomingEvents++;
      }
    });

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user event analytics',
      error: error.message,
    });
  }
};

// Get connection growth analytics
exports.getConnectionGrowth = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('connections', 'createdAt');

    const connectionsByMonth = {};
    let totalConnections = 0;

    user.connections.forEach(connection => {
      const month = connection.createdAt.toLocaleString('default', { month: 'long', year: 'numeric' });
      connectionsByMonth[month] = (connectionsByMonth[month] || 0) + 1;
      totalConnections++;
    });

    const analytics = {
      totalConnections,
      connectionsByMonth,
      averageConnectionsPerMonth: totalConnections > 0 ? Math.round(totalConnections / Object.keys(connectionsByMonth).length) : 0,
    };

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching connection growth',
      error: error.message,
    });
  }
};

// Get user engagement analytics
exports.getUserEngagement = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('eventsAttending')
      .populate('eventsOrganized');

    const analytics = {
      profileCompleteness: 0,
      eventsAttended: user.eventsAttending.length,
      eventsOrganized: user.eventsOrganized.length,
      totalConnections: user.connections.length,
      lastActive: user.lastLogin,
      engagementScore: 0,
    };

    // Calculate profile completeness
    let completedFields = 0;
    const totalFields = 10;

    if (user.name) completedFields++;
    if (user.email) completedFields++;
    if (user.company) completedFields++;
    if (user.jobTitle) completedFields++;
    if (user.bio) completedFields++;
    if (user.phone) completedFields++;
    if (user.profileImage) completedFields++;
    if (user.interests && user.interests.length > 0) completedFields++;
    if (user.socialLinks && Object.keys(user.socialLinks).length > 0) completedFields++;
    if (user.eventsAttending.length > 0) completedFields++;

    analytics.profileCompleteness = Math.round((completedFields / totalFields) * 100);

    // Calculate engagement score (0-100)
    let score = 0;
    score += Math.min(analytics.eventsAttended * 5, 30); // Max 30 points for attending events
    score += Math.min(analytics.eventsOrganized * 10, 20); // Max 20 points for organizing events
    score += Math.min(analytics.totalConnections * 2, 25); // Max 25 points for connections
    score += Math.min(analytics.profileCompleteness * 0.25, 25); // Max 25 points for profile completeness

    analytics.engagementScore = Math.round(score);

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user engagement',
      error: error.message,
    });
  }
};

// Get analytics for a specific event (for organizers)
exports.getEventAnalytics = async (req, res) => {
  try {
    const { eventId } = req.params;

    const event = await Event.findById(eventId)
      .populate('attendees.user', 'name company jobTitle');

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
        message: 'Not authorized to view analytics for this event',
      });
    }

    const analytics = {
      totalRegistrations: event.attendees.length,
      attendeesByStatus: {
        registered: event.attendees.filter(a => a.status === 'registered').length,
        waitlisted: event.attendees.filter(a => a.status === 'waitlisted').length,
        attended: event.attendees.filter(a => a.status === 'attended').length,
        cancelled: event.attendees.filter(a => a.status === 'cancelled').length,
      },
      attendeesByCompany: {},
      registrationTrend: {},
      revenue: {
        total: event.price * event.attendees.filter(a => 
          a.status === 'registered' || a.status === 'attended').length,
        perAttendee: event.price,
      },
      capacity: {
        total: event.capacity,
        filled: event.attendees.filter(a => 
          a.status === 'registered' || a.status === 'attended').length,
        utilization: Math.round(
          (event.attendees.filter(a => 
            a.status === 'registered' || a.status === 'attended').length / event.capacity) * 100
        ),
      },
      views: event.analytics.views,
      shares: event.analytics.shares,
    };

    // Analyze attendees by company
    event.attendees.forEach(attendee => {
      if (attendee.user && attendee.user.company) {
        const company = attendee.user.company;
        analytics.attendeesByCompany[company] = (analytics.attendeesByCompany[company] || 0) + 1;
      }
    });

    // Registration trend by day (simplified)
    event.attendees.forEach(attendee => {
      const registrationDate = attendee.registeredAt.toDateString();
      analytics.registrationTrend[registrationDate] = 
        (analytics.registrationTrend[registrationDate] || 0) + 1;
    });

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching event analytics',
      error: error.message,
    });
  }
};

// Get organizer summary analytics
exports.getOrganizerSummary = async (req, res) => {
  try {
    const events = await Event.find({ organizer: req.user._id });

    const summary = {
      totalEvents: events.length,
      eventsByStatus: {
        draft: events.filter(e => e.status === 'draft').length,
        active: events.filter(e => e.status === 'active').length,
        completed: events.filter(e => e.status === 'completed').length,
        cancelled: events.filter(e => e.status === 'cancelled').length,
      },
      totalAttendees: 0,
      totalRevenue: 0,
      averageAttendance: 0,
      topPerformingEvent: null,
      upcomingEvents: 0,
    };

    const currentDate = new Date();
    let maxAttendees = 0;
    let totalCapacityFilled = 0;

    events.forEach(event => {
      const attendeeCount = event.attendees.filter(a => 
        a.status === 'registered' || a.status === 'attended').length;
      
      summary.totalAttendees += attendeeCount;
      summary.totalRevenue += event.price * attendeeCount;
      
      if (attendeeCount > maxAttendees) {
        maxAttendees = attendeeCount;
        summary.topPerformingEvent = {
          title: event.title,
          attendees: attendeeCount,
          revenue: event.price * attendeeCount,
        };
      }

      if (event.dateTime > currentDate && event.status === 'active') {
        summary.upcomingEvents++;
      }

      if (event.status === 'completed') {
        totalCapacityFilled += (attendeeCount / event.capacity) * 100;
      }
    });

    const completedEvents = summary.eventsByStatus.completed;
    summary.averageAttendance = completedEvents > 0 ? 
      Math.round(totalCapacityFilled / completedEvents) : 0;

    res.json({
      success: true,
      data: summary,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching organizer summary',
      error: error.message,
    });
  }
};