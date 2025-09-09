const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminUserSchema = new mongoose.Schema({
  username: {
    type: String,
    required: [true, 'Username is required'],
    unique: true,
    lowercase: true,
    trim: true,
    minlength: 3,
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: 6,
    select: false,
  },
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
  },
  role: {
    type: String,
    enum: ['owner', 'user'],
    default: 'user',
  },
  permissions: {
    createAdmins: {
      type: Boolean,
      default: false,
    },
    manageUsers: {
      type: Boolean,
      default: true,
    },
    manageEvents: {
      type: Boolean,
      default: true,
    },
    viewAnalytics: {
      type: Boolean,
      default: true,
    },
    moderateContent: {
      type: Boolean,
      default: true,
    },
    systemSettings: {
      type: Boolean,
      default: false,
    },
    deleteData: {
      type: Boolean,
      default: false,
    },
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  lastLogin: {
    type: Date,
  },
  loginAttempts: {
    type: Number,
    default: 0,
  },
  lockUntil: {
    type: Date,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'AdminUser',
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Virtual for account lock status
adminUserSchema.virtual('isLocked').get(function() {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Update permissions based on role
adminUserSchema.pre('save', function(next) {
  if (this.isModified('role')) {
    if (this.role === 'owner') {
      // Owner has all permissions
      this.permissions = {
        createAdmins: true,
        manageUsers: true,
        manageEvents: true,
        viewAnalytics: true,
        moderateContent: true,
        systemSettings: true,
        deleteData: true,
      };
    } else {
      // User admin has limited permissions
      this.permissions = {
        createAdmins: false,
        manageUsers: true,
        manageEvents: true,
        viewAnalytics: true,
        moderateContent: true,
        systemSettings: false,
        deleteData: false,
      };
    }
  }
  this.updatedAt = new Date();
  next();
});

// Hash password before saving
adminUserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
adminUserSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Increment login attempts
adminUserSchema.methods.incLoginAttempts = async function() {
  // Reset attempts if lock has expired
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return await this.updateOne({
      $set: { loginAttempts: 1 },
      $unset: { lockUntil: 1 }
    });
  }
  
  const updates = { $inc: { loginAttempts: 1 } };
  const maxAttempts = 5;
  const lockTime = 2 * 60 * 60 * 1000; // 2 hours
  
  if (this.loginAttempts + 1 >= maxAttempts && !this.isLocked) {
    updates.$set = { lockUntil: Date.now() + lockTime };
  }
  
  return await this.updateOne(updates);
};

// Reset login attempts
adminUserSchema.methods.resetLoginAttempts = async function() {
  return await this.updateOne({
    $set: { loginAttempts: 0, lastLogin: new Date() },
    $unset: { lockUntil: 1 }
  });
};

const AdminUser = mongoose.model('AdminUser', adminUserSchema);

module.exports = AdminUser;