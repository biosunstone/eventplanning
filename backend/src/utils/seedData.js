require('dotenv').config();
const mongoose = require('mongoose');
const AdminUser = require('../models/AdminUser');
const User = require('../models/User');
const Event = require('../models/Event');

const seedDatabase = async () => {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/event_planning_app');
    console.log('Connected to MongoDB');

    // Clear existing data
    await AdminUser.deleteMany({});
    await User.deleteMany({});
    await Event.deleteMany({});
    console.log('Cleared existing data');

    // Create admin users
    const ownerAdmin = await AdminUser.create({
      username: 'admin',
      email: 'admin@eventapp.com',
      password: 'owner123',
      name: 'Owner Admin',
      role: 'owner',
    });

    const userAdmin = await AdminUser.create({
      username: 'useradmin',
      email: 'useradmin@eventapp.com',
      password: 'admin123',
      name: 'User Admin',
      role: 'user',
      createdBy: ownerAdmin._id,
    });

    console.log('Created admin users');

    // Create regular users
    const users = [];
    const userProfiles = [
      {
        email: 'demo@example.com',
        password: 'password123',
        name: 'Demo User',
        company: 'Tech Corp',
        jobTitle: 'Software Engineer',
        bio: 'Passionate about technology and networking',
        interests: ['Technology', 'Programming', 'AI'],
      },
      {
        email: 'john.doe@company.com',
        password: 'password123',
        name: 'John Doe',
        company: 'StartupXYZ',
        jobTitle: 'Product Manager',
        bio: 'Building innovative products',
        interests: ['Product Management', 'Startups', 'Innovation'],
      },
      {
        email: 'jane.smith@consulting.com',
        password: 'password123',
        name: 'Jane Smith',
        company: 'Consulting Firm',
        jobTitle: 'Senior Consultant',
        bio: 'Strategy and business transformation expert',
        interests: ['Consulting', 'Strategy', 'Business'],
      },
      {
        email: 'alex.wilson@design.co',
        password: 'password123',
        name: 'Alex Wilson',
        company: 'Design Co',
        jobTitle: 'UX Designer',
        bio: 'Creating beautiful and user-friendly experiences',
        interests: ['Design', 'UX', 'Creative'],
      },
      {
        email: 'sarah.brown@marketing.com',
        password: 'password123',
        name: 'Sarah Brown',
        company: 'Marketing Agency',
        jobTitle: 'Marketing Director',
        bio: 'Digital marketing and brand strategy specialist',
        interests: ['Marketing', 'Branding', 'Digital'],
      },
    ];

    for (const userProfile of userProfiles) {
      const user = await User.create(userProfile);
      users.push(user);
    }

    console.log('Created regular users');

    // Create sample events
    const eventData = [
      {
        title: 'Tech Conference 2024',
        description: 'Join industry leaders for the biggest tech conference of the year. Featuring keynotes, workshops, and networking opportunities.',
        organizer: users[0]._id,
        category: 'conference',
        status: 'active',
        dateTime: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days from now
        endDateTime: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000 + 8 * 60 * 60 * 1000), // 8 hours later
        location: {
          venue: 'Convention Center',
          address: '123 Main Street',
          city: 'San Francisco',
          state: 'CA',
          country: 'USA',
          zipCode: '94105',
        },
        isVirtual: false,
        capacity: 500,
        price: 299.99,
        tags: ['technology', 'innovation', 'networking'],
        sessions: [
          {
            title: 'AI and the Future of Work',
            description: 'Exploring how AI will transform industries',
            speaker: 'Dr. Tech Expert',
            startTime: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            endTime: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000),
            location: 'Main Hall',
          },
        ],
      },
      {
        title: 'Digital Marketing Workshop',
        description: 'Learn the latest digital marketing strategies and tools in this hands-on workshop.',
        organizer: users[4]._id,
        category: 'workshop',
        status: 'active',
        dateTime: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000), // 15 days from now
        endDateTime: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000 + 4 * 60 * 60 * 1000), // 4 hours later
        location: {
          venue: 'Learning Hub',
          address: '456 Business Ave',
          city: 'New York',
          state: 'NY',
          country: 'USA',
          zipCode: '10001',
        },
        isVirtual: false,
        capacity: 50,
        price: 149.99,
        tags: ['marketing', 'digital', 'workshop'],
      },
      {
        title: 'Startup Networking Mixer',
        description: 'Connect with fellow entrepreneurs, investors, and startup enthusiasts in a casual networking environment.',
        organizer: users[1]._id,
        category: 'networking',
        status: 'active',
        dateTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
        endDateTime: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000 + 3 * 60 * 60 * 1000), // 3 hours later
        location: {
          venue: 'Rooftop Bar',
          address: '789 Startup Street',
          city: 'Austin',
          state: 'TX',
          country: 'USA',
          zipCode: '73301',
        },
        isVirtual: false,
        capacity: 100,
        price: 0, // Free event
        tags: ['networking', 'startup', 'entrepreneur'],
      },
      {
        title: 'Virtual UX Design Seminar',
        description: 'An online seminar covering the latest trends and best practices in UX design.',
        organizer: users[3]._id,
        category: 'seminar',
        status: 'active',
        dateTime: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000), // 10 days from now
        endDateTime: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000 + 2 * 60 * 60 * 1000), // 2 hours later
        location: {
          venue: 'Online',
          address: 'Virtual Event',
          city: 'Virtual',
          state: '',
          country: 'Online',
          zipCode: '',
        },
        isVirtual: true,
        virtualLink: 'https://zoom.us/j/example',
        capacity: 200,
        price: 49.99,
        tags: ['ux', 'design', 'virtual'],
      },
      {
        title: 'Business Strategy Completed Event',
        description: 'This was a past event about business strategy and planning.',
        organizer: users[2]._id,
        category: 'conference',
        status: 'completed',
        dateTime: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
        endDateTime: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000 + 6 * 60 * 60 * 1000), // 6 hours later
        location: {
          venue: 'Business Center',
          address: '321 Corporate Blvd',
          city: 'Chicago',
          state: 'IL',
          country: 'USA',
          zipCode: '60601',
        },
        isVirtual: false,
        capacity: 150,
        price: 199.99,
        tags: ['business', 'strategy', 'planning'],
      },
    ];

    const events = [];
    for (const event of eventData) {
      const createdEvent = await Event.create(event);
      events.push(createdEvent);
    }

    console.log('Created sample events');

    // Register some users for events
    for (let i = 0; i < users.length; i++) {
      const user = users[i];
      const eventsToAttend = events.slice(0, Math.min(3, events.length));
      
      for (const event of eventsToAttend) {
        if (event.organizer.toString() !== user._id.toString()) {
          await event.registerAttendee(user._id);
          await User.findByIdAndUpdate(user._id, {
            $addToSet: { eventsAttending: event._id }
          });
        }
      }
      
      // Update user's organized events
      const organizedEvents = events.filter(e => e.organizer.toString() === user._id.toString());
      if (organizedEvents.length > 0) {
        await User.findByIdAndUpdate(user._id, {
          eventsOrganized: organizedEvents.map(e => e._id)
        });
      }
    }

    console.log('Registered users for events');

    // Create some connections between users
    for (let i = 0; i < users.length; i++) {
      for (let j = i + 1; j < Math.min(i + 3, users.length); j++) {
        await User.findByIdAndUpdate(users[i]._id, {
          $addToSet: { connections: users[j]._id }
        });
        await User.findByIdAndUpdate(users[j]._id, {
          $addToSet: { connections: users[i]._id }
        });
      }
    }

    console.log('Created user connections');

    console.log('\n=== Seed Data Created Successfully ===');
    console.log('\nAdmin Login Credentials:');
    console.log('Owner Admin: admin / owner123');
    console.log('User Admin: useradmin / admin123');
    console.log('\nSample User Credentials:');
    console.log('demo@example.com / password123');
    console.log('john.doe@company.com / password123');
    console.log('jane.smith@consulting.com / password123');
    console.log('alex.wilson@design.co / password123');
    console.log('sarah.brown@marketing.com / password123');

    console.log(`\nCreated:
- ${await AdminUser.countDocuments()} admin users
- ${await User.countDocuments()} regular users  
- ${await Event.countDocuments()} events
`);

  } catch (error) {
    console.error('Error seeding database:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from database');
    process.exit(0);
  }
};

// Run the seed function
seedDatabase();