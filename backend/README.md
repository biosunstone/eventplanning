# Event Planning App - Node.js Backend

A comprehensive REST API backend for the Event Planning App built with Node.js, Express.js, and MongoDB.

## Features

- **Authentication & Authorization**
  - JWT-based authentication
  - Role-based access control (Admin/User)
  - Account lockout protection
  - Password hashing with bcrypt

- **User Management**
  - User profiles and social connections
  - Professional networking features
  - User search and recommendations

- **Event Management**
  - Create, update, delete events
  - Event registration and check-in
  - Capacity management and waitlists
  - Event categories and search

- **Admin Panel**
  - Dashboard with analytics
  - User and event management
  - Content moderation
  - System health monitoring
  - Backup operations

- **Analytics**
  - User engagement metrics
  - Event performance analytics
  - Revenue tracking
  - System usage statistics

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (jsonwebtoken)
- **Security**: Helmet, CORS, Rate limiting
- **Validation**: express-validator
- **Logging**: Morgan
- **Environment**: dotenv

## Installation

1. **Clone the repository**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Update the `.env` file with your configuration:
   ```
   PORT=5000
   NODE_ENV=development
   MONGODB_URI=mongodb://localhost:27017/event_planning_app
   JWT_SECRET=your_super_secret_jwt_key_here
   JWT_EXPIRE=30d
   CORS_ORIGIN=http://localhost:3000
   ```

4. **Start MongoDB**
   Make sure MongoDB is running on your system.

5. **Run the server**
   ```bash
   # Development mode with auto-restart
   npm run dev
   
   # Production mode
   npm start
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/admin/login` - Admin login
- `POST /api/auth/admin/create-owner` - Create owner admin (one-time setup)
- `GET /api/auth/me` - Get current user/admin profile
- `PUT /api/auth/me` - Update profile
- `POST /api/auth/change-password` - Change password
- `POST /api/auth/logout` - Logout

### Events
- `GET /api/events` - Get all events (with filters)
- `GET /api/events/:id` - Get single event
- `POST /api/events` - Create event (authenticated users)
- `PUT /api/events/:id` - Update event (organizer only)
- `DELETE /api/events/:id` - Delete event (organizer only)
- `POST /api/events/:id/register` - Register for event
- `POST /api/events/:id/unregister` - Unregister from event
- `POST /api/events/:id/checkin` - Check in to event
- `GET /api/events/user/attending` - Get user's attending events
- `GET /api/events/user/organized` - Get user's organized events

### Users
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users/connections` - Get user connections
- `POST /api/users/connections/send/:userId` - Send connection request
- `DELETE /api/users/connections/:userId` - Remove connection
- `GET /api/users/search` - Search users
- `GET /api/users/suggestions` - Get user suggestions

### Admin Panel
- `GET /api/admin/dashboard/stats` - Dashboard statistics
- `GET /api/admin/dashboard/system-health` - System health status
- `GET /api/admin/users` - Get all users (admin only)
- `GET /api/admin/events` - Get all events (admin only)
- `GET /api/admin/admins` - Get all admins (owner only)
- `POST /api/admin/admins` - Create admin (owner only)
- `PUT /api/admin/users/:id` - Update user (admin only)
- `DELETE /api/admin/users/:id` - Delete user (admin only)

### Analytics
- `GET /api/analytics/events/attended` - User event analytics
- `GET /api/analytics/connections/growth` - Connection growth
- `GET /api/analytics/engagement` - User engagement metrics
- `GET /api/analytics/events/:eventId/analytics` - Event analytics (organizer)

### System
- `GET /health` - Health check endpoint
- `GET /` - API information

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

### Admin Roles

- **Owner Admin**: Full system access, can create other admins
- **User Admin**: Limited access, cannot create admins or access system settings

### Permissions

- `createAdmins` - Create and manage admin users
- `manageUsers` - Manage regular users
- `manageEvents` - Manage events
- `viewAnalytics` - Access analytics
- `moderateContent` - Moderate user content
- `systemSettings` - Access system settings
- `deleteData` - Delete users/events

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": [] // Validation errors (if applicable)
}
```

## Rate Limiting

- Default: 100 requests per 15 minutes per IP
- Configurable via environment variables

## Security Features

- Helmet.js for security headers
- CORS protection
- Request rate limiting
- Input validation and sanitization
- Password hashing
- Account lockout protection
- JWT token expiration

## Development

1. **Run in development mode**
   ```bash
   npm run dev
   ```

2. **Run tests**
   ```bash
   npm test
   ```

3. **Lint code**
   ```bash
   npm run lint
   ```

## Database Models

### User
- Profile information
- Social connections
- Events (attending/organizing)
- Authentication data

### AdminUser
- Admin credentials
- Role and permissions
- Security features (lockout, attempts)

### Event
- Event details and settings
- Attendee management
- Analytics data
- Location and pricing

## Deployment

1. Set `NODE_ENV=production`
2. Update MongoDB connection string
3. Set secure JWT secret
4. Configure CORS for your domain
5. Run `npm start`

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| PORT | Server port | 5000 |
| NODE_ENV | Environment | development |
| MONGODB_URI | MongoDB connection string | Required |
| JWT_SECRET | JWT signing secret | Required |
| JWT_EXPIRE | JWT expiration time | 30d |
| CORS_ORIGIN | CORS allowed origin | http://localhost:3000 |
| RATE_LIMIT_WINDOW_MS | Rate limit window | 900000 |
| RATE_LIMIT_MAX_REQUESTS | Max requests per window | 100 |

## Support

For technical support or questions, please refer to the main project documentation or create an issue in the repository.