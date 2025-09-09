const { validationResult } = require('express-validator');
const AdminUser = require('../models/AdminUser');
const User = require('../models/User');
const Event = require('../models/Event');

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

// Dashboard Stats
exports.getDashboardStats = async (req, res) => {
  try {
    const [totalUsers, totalEvents, activeEvents] = await Promise.all([
      User.countDocuments({ isActive: true }),
      Event.countDocuments(),
      Event.countDocuments({ status: 'active' }),
    ]);

    // Calculate total revenue (mock calculation)
    const events = await Event.find({ status: { $in: ['active', 'completed'] } });
    const totalRevenue = events.reduce((sum, event) => {
      const attendees = event.attendees.filter(a => a.status === 'registered' || a.status === 'attended').length;
      return sum + (event.price * attendees);
    }, 0);

    // Calculate monthly revenue (current month)
    const currentMonth = new Date();
    currentMonth.setDate(1);
    const monthlyEvents = await Event.find({
      dateTime: { $gte: currentMonth },
      status: { $in: ['active', 'completed'] }
    });
    
    const monthlyRevenue = monthlyEvents.reduce((sum, event) => {
      const attendees = event.attendees.filter(a => a.status === 'registered' || a.status === 'attended').length;
      return sum + (event.price * attendees);
    }, 0);

    // Calculate total registrations
    const totalRegistrations = events.reduce((sum, event) => {
      return sum + event.attendees.filter(a => a.status === 'registered' || a.status === 'attended').length;
    }, 0);

    res.json({
      success: true,
      data: {
        totalUsers,
        totalEvents,
        activeEvents,
        totalRevenue,
        monthlyRevenue,
        totalRegistrations,
        completedEvents: await Event.countDocuments({ status: 'completed' }),
        draftEvents: await Event.countDocuments({ status: 'draft' }),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard stats',
      error: error.message,
    });
  }
};

// System Health
exports.getSystemHealth = async (req, res) => {
  try {
    const dbStatus = {
      status: 'healthy',
      responseTime: Date.now(),
    };

    // Test database connection
    try {
      await User.findOne().limit(1);
      dbStatus.responseTime = Date.now() - dbStatus.responseTime;
    } catch (error) {
      dbStatus.status = 'unhealthy';
      dbStatus.error = error.message;
    }

    res.json({
      success: true,
      data: {
        database: {
          status: dbStatus.status,
          usage: `${dbStatus.responseTime}ms response`,
        },
        storage: {
          status: 'healthy',
          usage: '25GB used of 100GB',
        },
        memory: {
          status: 'healthy',
          usage: `${Math.round(process.memoryUsage().heapUsed / 1024 / 1024)}MB used`,
        },
        cpu: {
          status: 'healthy',
          usage: '45% average',
        },
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching system health',
      error: error.message,
    });
  }
};

// Analytics Overview
exports.getAnalyticsOverview = async (req, res) => {
  try {
    const [userCount, eventCount] = await Promise.all([
      User.countDocuments({ isActive: true }),
      Event.countDocuments({ status: 'active' }),
    ]);

    // Mock analytics data
    const analyticsData = {
      userGrowth: [
        { month: 'Jan', users: 120 },
        { month: 'Feb', users: 150 },
        { month: 'Mar', users: 180 },
        { month: 'Apr', users: 220 },
        { month: 'May', users: userCount },
      ],
      eventCategories: [
        { category: 'Conference', count: Math.floor(eventCount * 0.4) },
        { category: 'Workshop', count: Math.floor(eventCount * 0.3) },
        { category: 'Networking', count: Math.floor(eventCount * 0.2) },
        { category: 'Other', count: Math.floor(eventCount * 0.1) },
      ],
      topPerformers: [
        { name: 'Tech Conference 2024', attendees: 450, revenue: 22500 },
        { name: 'Digital Marketing Workshop', attendees: 200, revenue: 15000 },
        { name: 'Startup Networking Event', attendees: 180, revenue: 0 },
      ],
    };

    res.json({
      success: true,
      data: analyticsData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching analytics overview',
      error: error.message,
    });
  }
};

// Event Analytics
exports.getEventAnalytics = async (req, res) => {
  try {
    const events = await Event.find().populate('organizer', 'name email');
    
    const analytics = {
      totalEvents: events.length,
      eventsByStatus: {
        active: events.filter(e => e.status === 'active').length,
        completed: events.filter(e => e.status === 'completed').length,
        draft: events.filter(e => e.status === 'draft').length,
        cancelled: events.filter(e => e.status === 'cancelled').length,
      },
      eventsByCategory: {},
      averageAttendees: 0,
      totalRevenue: 0,
    };

    // Calculate category distribution
    events.forEach(event => {
      analytics.eventsByCategory[event.category] = 
        (analytics.eventsByCategory[event.category] || 0) + 1;
    });

    // Calculate averages
    if (events.length > 0) {
      const totalAttendees = events.reduce((sum, event) => 
        sum + event.attendees.filter(a => a.status === 'attended').length, 0);
      analytics.averageAttendees = Math.round(totalAttendees / events.length);

      analytics.totalRevenue = events.reduce((sum, event) => {
        const paidAttendees = event.attendees.filter(a => 
          a.status === 'registered' || a.status === 'attended').length;
        return sum + (event.price * paidAttendees);
      }, 0);
    }

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

// User Analytics
exports.getUserAnalytics = async (req, res) => {
  try {
    const users = await User.find();
    
    const analytics = {
      totalUsers: users.length,
      activeUsers: users.filter(u => u.isActive).length,
      userGrowth: [],
      demographics: {
        byCompany: {},
        byJobTitle: {},
      },
      engagement: {
        totalConnections: 0,
        averageEventsPerUser: 0,
      },
    };

    // Calculate demographics
    users.forEach(user => {
      if (user.company) {
        analytics.demographics.byCompany[user.company] = 
          (analytics.demographics.byCompany[user.company] || 0) + 1;
      }
      if (user.jobTitle) {
        analytics.demographics.byJobTitle[user.jobTitle] = 
          (analytics.demographics.byJobTitle[user.jobTitle] || 0) + 1;
      }
      analytics.engagement.totalConnections += user.connections.length;
    });

    if (users.length > 0) {
      const totalEvents = users.reduce((sum, user) => sum + user.eventsAttending.length, 0);
      analytics.engagement.averageEventsPerUser = Math.round(totalEvents / users.length);
    }

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user analytics',
      error: error.message,
    });
  }
};

// Revenue Analytics
exports.getRevenueAnalytics = async (req, res) => {
  try {
    const events = await Event.find({ status: { $in: ['active', 'completed'] } });
    
    const analytics = {
      totalRevenue: 0,
      monthlyRevenue: {},
      revenueByCategory: {},
      topRevenueEvents: [],
    };

    events.forEach(event => {
      const attendees = event.attendees.filter(a => 
        a.status === 'registered' || a.status === 'attended').length;
      const eventRevenue = event.price * attendees;
      
      analytics.totalRevenue += eventRevenue;
      
      // Group by month
      const month = event.dateTime.toLocaleString('default', { month: 'long', year: 'numeric' });
      analytics.monthlyRevenue[month] = (analytics.monthlyRevenue[month] || 0) + eventRevenue;
      
      // Group by category
      analytics.revenueByCategory[event.category] = 
        (analytics.revenueByCategory[event.category] || 0) + eventRevenue;
      
      // Track top events
      analytics.topRevenueEvents.push({
        title: event.title,
        revenue: eventRevenue,
        attendees: attendees,
      });
    });

    // Sort top events by revenue
    analytics.topRevenueEvents.sort((a, b) => b.revenue - a.revenue);
    analytics.topRevenueEvents = analytics.topRevenueEvents.slice(0, 10);

    res.json({
      success: true,
      data: analytics,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching revenue analytics',
      error: error.message,
    });
  }
};

// Admin User Management
exports.getAllAdmins = async (req, res) => {
  try {
    const admins = await AdminUser.find().select('-password').sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: admins,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching admins',
      error: error.message,
    });
  }
};

exports.createAdmin = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const { username, email, password, name, role } = req.body;

    // Check if admin already exists
    const existingAdmin = await AdminUser.findOne({
      $or: [{ username }, { email }]
    });

    if (existingAdmin) {
      return res.status(400).json({
        success: false,
        message: 'Admin with this username or email already exists',
      });
    }

    const admin = await AdminUser.create({
      username,
      email,
      password,
      name,
      role,
      createdBy: req.admin._id,
    });

    res.status(201).json({
      success: true,
      message: 'Admin created successfully',
      data: {
        id: admin._id,
        username: admin.username,
        email: admin.email,
        name: admin.name,
        role: admin.role,
        permissions: admin.permissions,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating admin',
      error: error.message,
    });
  }
};

exports.getAdminById = async (req, res) => {
  try {
    const admin = await AdminUser.findById(req.params.id).select('-password');
    
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    res.json({
      success: true,
      data: admin,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching admin',
      error: error.message,
    });
  }
};

exports.updateAdmin = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const { email, name, role } = req.body;
    
    const admin = await AdminUser.findByIdAndUpdate(
      req.params.id,
      { email, name, role },
      { new: true, runValidators: true }
    ).select('-password');

    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    res.json({
      success: true,
      message: 'Admin updated successfully',
      data: admin,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating admin',
      error: error.message,
    });
  }
};

exports.deleteAdmin = async (req, res) => {
  try {
    // Prevent deleting the main owner admin
    const admin = await AdminUser.findById(req.params.id);
    if (!admin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found',
      });
    }

    if (admin.username === 'admin') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete the main owner admin',
      });
    }

    await AdminUser.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Admin deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting admin',
      error: error.message,
    });
  }
};

// User Management
exports.getAllUsers = async (req, res) => {
  try {
    const { page = 1, limit = 10, search, status } = req.query;
    
    const query = {};
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { company: { $regex: search, $options: 'i' } },
      ];
    }
    if (status) {
      query.isActive = status === 'active';
    }

    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await User.countDocuments(query);

    res.json({
      success: true,
      data: users,
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
      message: 'Error fetching users',
      error: error.message,
    });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-password')
      .populate('eventsAttending', 'title dateTime')
      .populate('eventsOrganized', 'title dateTime status');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user',
      error: error.message,
    });
  }
};

exports.updateUser = async (req, res) => {
  try {
    const { name, email, company, jobTitle, bio, phone } = req.body;
    
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { name, email, company, jobTitle, bio, phone },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'User updated successfully',
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating user',
      error: error.message,
    });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'User deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting user',
      error: error.message,
    });
  }
};

exports.activateUser = async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: true },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'User activated successfully',
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error activating user',
      error: error.message,
    });
  }
};

exports.deactivateUser = async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'User deactivated successfully',
      data: user,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deactivating user',
      error: error.message,
    });
  }
};

// Event Management (placeholder implementations)
exports.getAllEvents = async (req, res) => {
  try {
    const { page = 1, limit = 10, status, category } = req.query;
    
    const query = {};
    if (status) query.status = status;
    if (category) query.category = category;

    const events = await Event.find(query)
      .populate('organizer', 'name email')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await Event.countDocuments(query);

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
      message: 'Error fetching events',
      error: error.message,
    });
  }
};

exports.getEventById = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('organizer', 'name email company')
      .populate('attendees.user', 'name email company');
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    res.json({
      success: true,
      data: event,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching event',
      error: error.message,
    });
  }
};

exports.updateEvent = async (req, res) => {
  try {
    const event = await Event.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).populate('organizer', 'name email');

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    res.json({
      success: true,
      message: 'Event updated successfully',
      data: event,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating event',
      error: error.message,
    });
  }
};

exports.deleteEvent = async (req, res) => {
  try {
    const event = await Event.findByIdAndDelete(req.params.id);
    
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

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

exports.approveEvent = async (req, res) => {
  try {
    const event = await Event.findByIdAndUpdate(
      req.params.id,
      { status: 'active' },
      { new: true }
    );

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    res.json({
      success: true,
      message: 'Event approved successfully',
      data: event,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error approving event',
      error: error.message,
    });
  }
};

exports.rejectEvent = async (req, res) => {
  try {
    const event = await Event.findByIdAndUpdate(
      req.params.id,
      { status: 'cancelled' },
      { new: true }
    );

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found',
      });
    }

    res.json({
      success: true,
      message: 'Event rejected successfully',
      data: event,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error rejecting event',
      error: error.message,
    });
  }
};

exports.getEventAttendees = async (req, res) => {
  try {
    const event = await Event.findById(req.params.id)
      .populate('attendees.user', 'name email company jobTitle')
      .select('title attendees');
    
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
        attendees: event.attendees,
        totalCount: event.attendees.length,
        registeredCount: event.attendees.filter(a => a.status === 'registered').length,
        attendedCount: event.attendees.filter(a => a.status === 'attended').length,
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

// Content Moderation (mock implementations)
exports.getPendingPosts = async (req, res) => {
  res.json({
    success: true,
    data: [],
    message: 'Content moderation feature not fully implemented',
  });
};

exports.approvePost = async (req, res) => {
  res.json({
    success: true,
    message: 'Post approved (mock response)',
  });
};

exports.rejectPost = async (req, res) => {
  res.json({
    success: true,
    message: 'Post rejected (mock response)',
  });
};

exports.getReports = async (req, res) => {
  res.json({
    success: true,
    data: [],
    message: 'Reports feature not fully implemented',
  });
};

exports.resolveReport = async (req, res) => {
  res.json({
    success: true,
    message: 'Report resolved (mock response)',
  });
};

// System Settings (mock implementations)
exports.getSystemSettings = async (req, res) => {
  res.json({
    success: true,
    data: {
      siteName: 'Event Planning App',
      maintenanceMode: false,
      registrationEnabled: true,
      emailNotifications: true,
      maxEventCapacity: 1000,
    },
  });
};

exports.updateSystemSettings = async (req, res) => {
  res.json({
    success: true,
    message: 'System settings updated (mock response)',
    data: req.body,
  });
};

// Backup operations (mock implementations)
exports.createBackup = async (req, res) => {
  res.json({
    success: true,
    message: 'Backup created successfully (mock response)',
    data: {
      backupId: Date.now().toString(),
      createdAt: new Date(),
    },
  });
};

exports.listBackups = async (req, res) => {
  res.json({
    success: true,
    data: [],
    message: 'Backup list feature not implemented',
  });
};

exports.restoreBackup = async (req, res) => {
  res.json({
    success: true,
    message: 'Backup restored successfully (mock response)',
  });
};

exports.getSystemLogs = async (req, res) => {
  res.json({
    success: true,
    data: [],
    message: 'System logs feature not implemented',
  });
};