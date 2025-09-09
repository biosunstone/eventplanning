const { validationResult } = require('express-validator');
const User = require('../models/User');
const AdminUser = require('../models/AdminUser');
const { generateUserToken, generateAdminToken } = require('../utils/jwt');

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

// Register new user
exports.registerUser = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const { email, password, name, company, jobTitle } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email',
      });
    }

    // Create user
    const user = await User.create({
      email,
      password,
      name,
      company,
      jobTitle,
    });

    // Generate token
    const token = generateUserToken(user);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: user.getPublicProfile(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error registering user',
      error: error.message,
    });
  }
};

// Login user
exports.loginUser = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const { email, password } = req.body;

    // Find user and include password
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate token
    const token = generateUserToken(user);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: user.getPublicProfile(),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error logging in',
      error: error.message,
    });
  }
};

// Login admin
exports.loginAdmin = async (req, res) => {
  try {
    const validationError = handleValidationErrors(req, res);
    if (validationError) return validationError;

    const { username, password } = req.body;

    // Find admin and include password
    const admin = await AdminUser.findOne({ username }).select('+password');
    if (!admin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if account is locked
    if (admin.isLocked) {
      return res.status(423).json({
        success: false,
        message: 'Account is temporarily locked due to multiple failed login attempts',
      });
    }

    // Check if admin is active
    if (!admin.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Check password
    const isMatch = await admin.comparePassword(password);
    if (!isMatch) {
      await admin.incLoginAttempts();
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Reset login attempts and update last login
    await admin.resetLoginAttempts();

    // Generate token
    const token = generateAdminToken(admin);

    res.json({
      success: true,
      message: 'Admin login successful',
      token,
      admin: {
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
      message: 'Error logging in admin',
      error: error.message,
    });
  }
};

// Create owner admin (one-time setup)
exports.createOwnerAdmin = async (req, res) => {
  try {
    // Check if any admin exists
    const existingAdmin = await AdminUser.findOne();
    if (existingAdmin) {
      return res.status(400).json({
        success: false,
        message: 'Admin system already initialized',
      });
    }

    const { username, email, password, name } = req.body;

    // Create owner admin
    const admin = await AdminUser.create({
      username,
      email,
      password,
      name,
      role: 'owner',
    });

    const token = generateAdminToken(admin);

    res.status(201).json({
      success: true,
      message: 'Owner admin created successfully',
      token,
      admin: {
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
      message: 'Error creating owner admin',
      error: error.message,
    });
  }
};

// Get current user/admin
exports.getMe = async (req, res) => {
  try {
    if (req.admin) {
      res.json({
        success: true,
        admin: {
          id: req.admin._id,
          username: req.admin.username,
          email: req.admin.email,
          name: req.admin.name,
          role: req.admin.role,
          permissions: req.admin.permissions,
        },
      });
    } else {
      res.json({
        success: true,
        user: req.user.getPublicProfile(),
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching profile',
      error: error.message,
    });
  }
};

// Update profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, company, jobTitle, bio, phone, interests, socialLinks } = req.body;

    if (req.admin) {
      // Update admin profile
      const admin = await AdminUser.findByIdAndUpdate(
        req.admin._id,
        { name, email: req.body.email },
        { new: true, runValidators: true }
      );

      res.json({
        success: true,
        message: 'Admin profile updated successfully',
        admin: {
          id: admin._id,
          username: admin.username,
          email: admin.email,
          name: admin.name,
          role: admin.role,
          permissions: admin.permissions,
        },
      });
    } else {
      // Update user profile
      const user = await User.findByIdAndUpdate(
        req.user._id,
        { name, company, jobTitle, bio, phone, interests, socialLinks },
        { new: true, runValidators: true }
      );

      res.json({
        success: true,
        message: 'Profile updated successfully',
        user: user.getPublicProfile(),
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message,
    });
  }
};

// Change password
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters long',
      });
    }

    const Model = req.admin ? AdminUser : User;
    const user = await Model.findById(req.user._id).select('+password');

    // Check current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error changing password',
      error: error.message,
    });
  }
};

// Forgot password (placeholder)
exports.forgotPassword = async (req, res) => {
  res.json({
    success: true,
    message: 'Password reset instructions sent to email (feature not implemented)',
  });
};

// Reset password (placeholder)
exports.resetPassword = async (req, res) => {
  res.json({
    success: true,
    message: 'Password reset successful (feature not implemented)',
  });
};

// Logout
exports.logout = async (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully',
  });
};

// Refresh token (placeholder)
exports.refreshToken = async (req, res) => {
  res.json({
    success: false,
    message: 'Refresh token feature not implemented',
  });
};