const { verifyToken } = require('../utils/jwt');
const AdminUser = require('../models/AdminUser');
const User = require('../models/User');

// Protect routes - verify JWT token
const protect = async (req, res, next) => {
  let token;

  // Check for token in Authorization header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Check for token in cookies (if using cookie-based auth)
  if (!token && req.cookies && req.cookies.token) {
    token = req.cookies.token;
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access denied. No token provided.',
    });
  }

  try {
    const decoded = verifyToken(token);
    
    // Attach user info to request
    if (decoded.type === 'admin') {
      const admin = await AdminUser.findById(decoded.id).select('-password');
      if (!admin) {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. Admin not found.',
        });
      }
      
      if (!admin.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Account is deactivated.',
        });
      }
      
      req.admin = admin;
      req.user = admin; // For compatibility
    } else if (decoded.type === 'user') {
      const user = await User.findById(decoded.id).select('-password');
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. User not found.',
        });
      }
      
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Account is deactivated.',
        });
      }
      
      req.user = user;
    }
    
    req.tokenPayload = decoded;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired. Please login again.',
      });
    }
    
    return res.status(401).json({
      success: false,
      message: 'Invalid token.',
    });
  }
};

// Admin only access
const adminOnly = (req, res, next) => {
  if (!req.admin) {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Admin privileges required.',
    });
  }
  next();
};

// Owner admin only access
const ownerOnly = (req, res, next) => {
  if (!req.admin || req.admin.role !== 'owner') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Owner privileges required.',
    });
  }
  next();
};

// Check specific admin permission
const requirePermission = (permission) => {
  return (req, res, next) => {
    if (!req.admin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.',
      });
    }
    
    if (!req.admin.permissions[permission]) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Missing permission: ${permission}`,
      });
    }
    
    next();
  };
};

// User only access
const userOnly = (req, res, next) => {
  if (req.admin) {
    // Allow admin access to user endpoints for management
    return next();
  }
  
  if (!req.user || req.tokenPayload.type !== 'user') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. User account required.',
    });
  }
  next();
};

// Optional auth - don't fail if no token
const optionalAuth = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (token) {
    try {
      const decoded = verifyToken(token);
      
      if (decoded.type === 'admin') {
        const admin = await AdminUser.findById(decoded.id).select('-password');
        if (admin && admin.isActive) {
          req.admin = admin;
          req.user = admin;
        }
      } else if (decoded.type === 'user') {
        const user = await User.findById(decoded.id).select('-password');
        if (user && user.isActive) {
          req.user = user;
        }
      }
      
      req.tokenPayload = decoded;
    } catch (error) {
      // Ignore token errors for optional auth
    }
  }
  
  next();
};

module.exports = {
  protect,
  adminOnly,
  ownerOnly,
  requirePermission,
  userOnly,
  optionalAuth,
};