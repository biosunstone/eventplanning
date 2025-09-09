const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Event title is required'],
    trim: true,
    maxlength: 200,
  },
  description: {
    type: String,
    required: [true, 'Event description is required'],
    maxlength: 2000,
  },
  organizer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  category: {
    type: String,
    required: true,
    enum: ['conference', 'workshop', 'networking', 'seminar', 'social', 'other'],
  },
  status: {
    type: String,
    enum: ['draft', 'active', 'completed', 'cancelled'],
    default: 'draft',
  },
  dateTime: {
    type: Date,
    required: [true, 'Event date and time is required'],
  },
  endDateTime: {
    type: Date,
    required: [true, 'Event end date and time is required'],
  },
  location: {
    venue: {
      type: String,
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
    city: {
      type: String,
      required: true,
    },
    state: String,
    country: {
      type: String,
      required: true,
    },
    zipCode: String,
    coordinates: {
      lat: Number,
      lng: Number,
    },
  },
  isVirtual: {
    type: Boolean,
    default: false,
  },
  virtualLink: {
    type: String,
    required: function() {
      return this.isVirtual;
    },
  },
  capacity: {
    type: Number,
    required: [true, 'Event capacity is required'],
    min: 1,
  },
  price: {
    type: Number,
    default: 0,
    min: 0,
  },
  currency: {
    type: String,
    default: 'USD',
    enum: ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
  },
  images: [{
    url: String,
    caption: String,
  }],
  coverImage: {
    type: String,
  },
  tags: [{
    type: String,
    lowercase: true,
  }],
  attendees: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    registeredAt: {
      type: Date,
      default: Date.now,
    },
    status: {
      type: String,
      enum: ['registered', 'waitlisted', 'attended', 'cancelled'],
      default: 'registered',
    },
    checkInTime: Date,
    ticketType: String,
  }],
  sessions: [{
    title: String,
    description: String,
    speaker: String,
    startTime: Date,
    endTime: Date,
    location: String,
  }],
  sponsors: [{
    name: String,
    logo: String,
    website: String,
    tier: {
      type: String,
      enum: ['platinum', 'gold', 'silver', 'bronze'],
    },
  }],
  settings: {
    registrationOpen: {
      type: Boolean,
      default: true,
    },
    requireApproval: {
      type: Boolean,
      default: false,
    },
    allowWaitlist: {
      type: Boolean,
      default: true,
    },
    showAttendeesCount: {
      type: Boolean,
      default: true,
    },
    allowCancellation: {
      type: Boolean,
      default: true,
    },
    cancellationDeadline: Date,
  },
  analytics: {
    views: {
      type: Number,
      default: 0,
    },
    shares: {
      type: Number,
      default: 0,
    },
    registrationConversion: {
      type: Number,
      default: 0,
    },
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

// Indexes for better query performance
eventSchema.index({ dateTime: 1, status: 1 });
eventSchema.index({ organizer: 1 });
eventSchema.index({ category: 1 });
eventSchema.index({ tags: 1 });
eventSchema.index({ 'location.city': 1 });

// Virtual for checking if event is active
eventSchema.virtual('isActive').get(function() {
  return this.status === 'active' && this.dateTime > new Date();
});

// Virtual for available spots
eventSchema.virtual('availableSpots').get(function() {
  const registered = this.attendees.filter(a => 
    a.status === 'registered' || a.status === 'attended'
  ).length;
  return Math.max(0, this.capacity - registered);
});

// Update the updatedAt timestamp
eventSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Method to register attendee
eventSchema.methods.registerAttendee = async function(userId) {
  const existingAttendee = this.attendees.find(
    a => a.user.toString() === userId.toString()
  );
  
  if (existingAttendee) {
    throw new Error('User already registered for this event');
  }
  
  if (this.availableSpots <= 0 && !this.settings.allowWaitlist) {
    throw new Error('Event is full');
  }
  
  this.attendees.push({
    user: userId,
    status: this.availableSpots > 0 ? 'registered' : 'waitlisted',
  });
  
  await this.save();
  return this;
};

// Method to check in attendee
eventSchema.methods.checkInAttendee = async function(userId) {
  const attendee = this.attendees.find(
    a => a.user.toString() === userId.toString()
  );
  
  if (!attendee) {
    throw new Error('User not registered for this event');
  }
  
  if (attendee.status !== 'registered') {
    throw new Error('User cannot check in with current status');
  }
  
  attendee.status = 'attended';
  attendee.checkInTime = new Date();
  
  await this.save();
  return this;
};

const Event = mongoose.model('Event', eventSchema);

module.exports = Event;