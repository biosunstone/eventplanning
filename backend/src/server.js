require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

// Import routes
const authRoutes = require('./routes/auth.routes');
const adminRoutes = require('./routes/admin.routes');
const userRoutes = require('./routes/user.routes');
const eventRoutes = require('./routes/event.routes');
const analyticsRoutes = require('./routes/analytics.routes');

// Import error handler
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Database connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/event_planning_app', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB connected successfully');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// Middleware
app.use(helmet());
// CORS configuration for Flutter app
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    // In production, allow all origins or specific domains
    if (process.env.NODE_ENV === 'production') {
      // Option 1: Allow all origins (easiest for mobile apps)
      return callback(null, true);
      
      // Option 2: Allow specific origins (uncomment and modify if needed)
      // const allowedOrigins = ['https://your-app.com', 'https://your-domain.com'];
      // if (allowedOrigins.indexOf(origin) !== -1) {
      //   callback(null, true);
      // } else {
      //   callback(new Error('Not allowed by CORS'));
      // }
    } else {
      // In development, allow localhost
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));
app.use(compression());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
});

app.use('/api', limiter);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/analytics', analyticsRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Event Planning App API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      admin: '/api/admin',
      users: '/api/users',
      events: '/api/events',
      analytics: '/api/analytics'
    }
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV,
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Event Planning API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      admin: '/api/admin',
      users: '/api/users',
      events: '/api/events',
      analytics: '/api/analytics',
      health: '/health',
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

// Error handling middleware
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  await connectDB();
  
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });
};

startServer();

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

module.exports = app;