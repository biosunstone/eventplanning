const { validationResult } = require('express-validator');
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

// Get user profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('eventsAttending', 'title dateTime location.city')
      .populate('eventsOrganized', 'title dateTime status')
      .populate('connections', 'name company jobTitle profileImage');

    res.json({
      success: true,
      data: user.getPublicProfile(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching profile',
      error: error.message,
    });
  }
};

// Update user profile
exports.updateProfile = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const { name, company, jobTitle, bio, phone, interests, socialLinks } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        name,
        company,
        jobTitle,
        bio,
        phone,
        interests,
        socialLinks,
      },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user.getPublicProfile(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message,
    });
  }
};

// Get user connections
exports.getConnections = async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('connections', 'name company jobTitle profileImage bio');

    res.json({
      success: true,
      data: user.connections,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching connections',
      error: error.message,
    });
  }
};

// Send connection request
exports.sendConnectionRequest = async (req, res) => {
  try {
    const { userId } = req.params;

    if (userId === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Cannot send connection request to yourself',
      });
    }

    const targetUser = await User.findById(userId);
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const currentUser = await User.findById(req.user._id);

    // Check if already connected
    if (currentUser.connections.includes(userId)) {
      return res.status(400).json({
        success: false,
        message: 'Already connected with this user',
      });
    }

    // For simplicity, we'll automatically accept connection requests
    // In a real app, you'd implement a pending requests system
    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { connections: userId }
    });

    await User.findByIdAndUpdate(userId, {
      $addToSet: { connections: req.user._id }
    });

    res.json({
      success: true,
      message: 'Connection established successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error sending connection request',
      error: error.message,
    });
  }
};

// Accept connection request (placeholder)
exports.acceptConnectionRequest = async (req, res) => {
  res.json({
    success: true,
    message: 'Connection request accepted (feature simplified)',
  });
};

// Reject connection request (placeholder)
exports.rejectConnectionRequest = async (req, res) => {
  res.json({
    success: true,
    message: 'Connection request rejected (feature simplified)',
  });
};

// Remove connection
exports.removeConnection = async (req, res) => {
  try {
    const { userId } = req.params;

    await User.findByIdAndUpdate(req.user._id, {
      $pull: { connections: userId }
    });

    await User.findByIdAndUpdate(userId, {
      $pull: { connections: req.user._id }
    });

    res.json({
      success: true,
      message: 'Connection removed successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error removing connection',
      error: error.message,
    });
  }
};

// Search users
exports.searchUsers = async (req, res) => {
  try {
    const { q, page = 1, limit = 10 } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required',
      });
    }

    const searchQuery = {
      isActive: true,
      _id: { $ne: req.user._id }, // Exclude current user
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { company: { $regex: q, $options: 'i' } },
        { jobTitle: { $regex: q, $options: 'i' } },
        { interests: { $in: [new RegExp(q, 'i')] } },
      ],
    };

    const users = await User.find(searchQuery)
      .select('name company jobTitle profileImage bio interests')
      .sort({ name: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const total = await User.countDocuments(searchQuery);

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
      message: 'Error searching users',
      error: error.message,
    });
  }
};

// Get user suggestions (based on similar interests, company, etc.)
exports.getUserSuggestions = async (req, res) => {
  try {
    const currentUser = await User.findById(req.user._id);
    
    const suggestionQuery = {
      isActive: true,
      _id: { 
        $ne: req.user._id,
        $nin: currentUser.connections 
      },
    };

    // Add criteria based on current user's profile
    const orConditions = [];
    
    if (currentUser.company) {
      orConditions.push({ company: currentUser.company });
    }
    
    if (currentUser.interests && currentUser.interests.length > 0) {
      orConditions.push({ interests: { $in: currentUser.interests } });
    }
    
    if (currentUser.jobTitle) {
      orConditions.push({ jobTitle: { $regex: currentUser.jobTitle, $options: 'i' } });
    }

    if (orConditions.length > 0) {
      suggestionQuery.$or = orConditions;
    }

    const suggestions = await User.find(suggestionQuery)
      .select('name company jobTitle profileImage bio interests')
      .limit(20)
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: suggestions,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching user suggestions',
      error: error.message,
    });
  }
};

// Get nearby users (placeholder - would need location data)
exports.getNearbyUsers = async (req, res) => {
  try {
    // Placeholder implementation - in a real app you'd use geolocation
    const users = await User.find({
      isActive: true,
      _id: { $ne: req.user._id },
    })
      .select('name company jobTitle profileImage bio')
      .limit(10)
      .sort({ lastLogin: -1 });

    res.json({
      success: true,
      data: users,
      message: 'Nearby users feature requires location permission',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching nearby users',
      error: error.message,
    });
  }
};

// Get public profile of another user
exports.getPublicProfile = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId)
      .select('-password -email')
      .populate('eventsOrganized', 'title dateTime status location.city');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (!user.isActive) {
      return res.status(404).json({
        success: false,
        message: 'User profile not available',
      });
    }

    // Check if users are connected
    const currentUser = await User.findById(req.user._id);
    const isConnected = currentUser.connections.includes(userId);

    const profileData = {
      ...user.toObject(),
      isConnected,
      mutualConnections: 0, // Placeholder
    };

    res.json({
      success: true,
      data: profileData,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching public profile',
      error: error.message,
    });
  }
};