const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
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
  profileImage: {
    type: String,
    default: null,
  },
  bio: {
    type: String,
    maxlength: 500,
  },
  company: {
    type: String,
  },
  jobTitle: {
    type: String,
  },
  phone: {
    type: String,
  },
  interests: [{
    type: String,
  }],
  socialLinks: {
    linkedin: String,
    twitter: String,
    website: String,
  },
  eventsAttending: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Event',
  }],
  eventsOrganized: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Event',
  }],
  connections: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  isActive: {
    type: Boolean,
    default: true,
  },
  lastLogin: {
    type: Date,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

// Update the updatedAt timestamp on save
userSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Get public profile
userSchema.methods.getPublicProfile = function() {
  const user = this.toObject();
  delete user.password;
  delete user.__v;
  return user;
};

const User = mongoose.model('User', userSchema);

module.exports = User;