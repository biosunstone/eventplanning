# API Specification - Event Planning Platform

## Overview

This document outlines the RESTful API specification for the Event Planning Platform backend. The API follows REST principles with JSON payloads and standard HTTP methods.

**Base URL:** `https://api.eventapp.com/v1`

**Authentication:** JWT Bearer tokens
```
Authorization: Bearer <jwt_token>
```

## 🔐 Authentication Endpoints

### POST /auth/login
Authenticate user and receive JWT token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "attendee"
  },
  "expiresAt": "2024-12-31T23:59:59Z"
}
```

### POST /auth/register
Register new user account.

**Request:**
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "user@example.com",
  "password": "password123",
  "role": "attendee"
}
```

### POST /auth/refresh
Refresh JWT token.

**Request:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

## 📅 Event Management Endpoints

### GET /events
Retrieve list of events.

**Query Parameters:**
- `limit` (int): Number of results (default: 20, max: 100)
- `offset` (int): Pagination offset
- `status` (string): Filter by status (upcoming, ongoing, past)
- `category` (string): Filter by category
- `search` (string): Search in title and description

**Response:**
```json
{
  "events": [
    {
      "id": "event_123",
      "title": "Tech Conference 2024",
      "description": "Annual technology conference",
      "startDate": "2024-06-15T09:00:00Z",
      "endDate": "2024-06-16T18:00:00Z",
      "location": "San Francisco, CA",
      "category": "technology",
      "status": "upcoming",
      "attendeeCount": 250,
      "maxAttendees": 500,
      "imageUrl": "https://cdn.eventapp.com/images/event_123.jpg",
      "settings": {
        "isPublic": true,
        "allowNetworking": true,
        "enableChat": true,
        "requireApproval": false
      },
      "organizer": {
        "id": "org_456",
        "name": "Tech Corp",
        "logo": "https://cdn.eventapp.com/logos/tech_corp.jpg"
      }
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 20,
    "offset": 0,
    "hasMore": true
  }
}
```

### POST /events
Create new event (organizer only).

**Request:**
```json
{
  "title": "New Conference",
  "description": "Conference description",
  "startDate": "2024-06-15T09:00:00Z",
  "endDate": "2024-06-16T18:00:00Z",
  "location": "New York, NY",
  "category": "business",
  "maxAttendees": 300,
  "settings": {
    "isPublic": true,
    "allowNetworking": true,
    "enableChat": true,
    "requireApproval": false
  }
}
```

### GET /events/{eventId}
Get specific event details.

### PUT /events/{eventId}
Update event (organizer only).

### DELETE /events/{eventId}
Delete event (organizer only).

## 👥 Attendee Management

### GET /events/{eventId}/attendees
Get event attendees list.

**Query Parameters:**
- `limit`, `offset`: Pagination
- `search`: Search by name or company
- `interests`: Filter by interests
- `jobTitles`: Filter by job titles

**Response:**
```json
{
  "attendees": [
    {
      "id": "att_123",
      "firstName": "John",
      "lastName": "Doe",
      "email": "john@example.com",
      "company": "Tech Corp",
      "jobTitle": "Software Engineer",
      "bio": "Passionate about technology",
      "profileImageUrl": "https://cdn.eventapp.com/profiles/att_123.jpg",
      "interests": ["AI", "Web Development"],
      "socialLinks": {
        "linkedin": "https://linkedin.com/in/johndoe",
        "twitter": "https://twitter.com/johndoe"
      },
      "networking": {
        "isAvailableForNetworking": true,
        "preferredTopics": ["Technology", "Startups"],
        "meetingPreference": "coffee_chat"
      }
    }
  ],
  "pagination": {
    "total": 250,
    "limit": 50,
    "offset": 0
  }
}
```

### GET /attendees/{attendeeId}
Get specific attendee profile.

### PUT /attendees/{attendeeId}
Update attendee profile (self or organizer).

## 📋 Session Management

### GET /events/{eventId}/sessions
Get event sessions/agenda.

**Response:**
```json
{
  "sessions": [
    {
      "id": "session_123",
      "title": "Keynote: Future of AI",
      "description": "Opening keynote about AI trends",
      "type": "keynote",
      "startTime": "2024-06-15T09:00:00Z",
      "endTime": "2024-06-15T10:00:00Z",
      "location": "Main Hall",
      "capacity": 500,
      "registeredCount": 320,
      "speakers": [
        {
          "id": "speaker_456",
          "name": "Dr. Sarah Johnson",
          "title": "AI Research Director",
          "company": "AI Labs",
          "bio": "Leading AI researcher",
          "imageUrl": "https://cdn.eventapp.com/speakers/speaker_456.jpg"
        }
      ],
      "resources": [
        {
          "id": "resource_789",
          "title": "Presentation Slides",
          "type": "slides",
          "url": "https://cdn.eventapp.com/resources/slides_789.pdf"
        }
      ],
      "liveFeatures": {
        "enablePolling": true,
        "enableQA": true,
        "enableChat": true,
        "enableReactions": true
      }
    }
  ]
}
```

### POST /events/{eventId}/sessions
Create session (organizer only).

### PUT /events/{eventId}/sessions/{sessionId}
Update session (organizer only).

### DELETE /events/{eventId}/sessions/{sessionId}
Delete session (organizer only).

## 📊 Live Session Features

### GET /sessions/{sessionId}/live
Get live session data.

**Response:**
```json
{
  "session": {
    "id": "session_123",
    "status": "live",
    "attendeeCount": 145,
    "reactions": {
      "👍": 23,
      "❤️": 18,
      "🎉": 12,
      "🤔": 5
    }
  },
  "polls": [
    {
      "id": "poll_456",
      "question": "What's your experience level?",
      "type": "multiple_choice",
      "options": ["Beginner", "Intermediate", "Advanced"],
      "isActive": true,
      "responses": {
        "Beginner": 45,
        "Intermediate": 67,
        "Advanced": 33
      }
    }
  ],
  "qa": [
    {
      "id": "qa_789",
      "question": "How does this apply to mobile development?",
      "askedBy": "att_123",
      "timestamp": "2024-06-15T09:15:00Z",
      "upvotes": 8,
      "isAnswered": false
    }
  ]
}
```

### POST /sessions/{sessionId}/reactions
Send reaction to live session.

**Request:**
```json
{
  "reaction": "👍"
}
```

### POST /sessions/{sessionId}/polls
Create poll (organizer/speaker only).

### POST /sessions/{sessionId}/polls/{pollId}/responses
Submit poll response.

### POST /sessions/{sessionId}/qa
Submit Q&A question.

## 🤝 Networking Features

### GET /events/{eventId}/networking/recommendations
Get networking recommendations.

**Response:**
```json
{
  "recommendations": [
    {
      "attendee": {
        "id": "att_456",
        "firstName": "Jane",
        "lastName": "Smith",
        "company": "StartupCo",
        "jobTitle": "Product Manager",
        "interests": ["AI", "Product Management"]
      },
      "matchScore": 0.85,
      "commonInterests": ["AI", "Startups"],
      "reason": "shared_interests_and_goals"
    }
  ]
}
```

### GET /networking/connections
Get user's connections.

### POST /networking/connections
Send connection request.

**Request:**
```json
{
  "targetUserId": "att_456",
  "message": "Hi! Would love to connect and discuss AI trends."
}
```

### PUT /networking/connections/{connectionId}
Update connection status (accept/reject).

### GET /networking/meetings
Get scheduled meetings.

### POST /networking/meetings
Schedule meeting.

**Request:**
```json
{
  "attendeeId": "att_456",
  "startTime": "2024-06-15T14:00:00Z",
  "duration": 30,
  "location": "Coffee area",
  "agenda": "Discuss AI collaboration opportunities"
}
```

## 💬 Messaging System

### GET /messages/conversations
Get user's conversations.

### GET /messages/conversations/{conversationId}
Get conversation messages.

### POST /messages/conversations/{conversationId}/messages
Send message.

**Request:**
```json
{
  "content": "Hello! Great presentation today.",
  "type": "text"
}
```

### POST /messages/conversations
Start new conversation.

## 📱 Community Features

### GET /events/{eventId}/community/posts
Get community board posts.

**Response:**
```json
{
  "posts": [
    {
      "id": "post_123",
      "author": {
        "id": "att_456",
        "name": "John Doe",
        "company": "Tech Corp",
        "imageUrl": "https://cdn.eventapp.com/profiles/att_456.jpg"
      },
      "content": "Great session on AI! Anyone want to discuss further?",
      "timestamp": "2024-06-15T10:30:00Z",
      "likes": 12,
      "comments": 5,
      "isLiked": false
    }
  ]
}
```

### POST /events/{eventId}/community/posts
Create community post.

### GET /events/{eventId}/photos
Get event photo gallery.

### POST /events/{eventId}/photos
Upload photo to gallery.

## 📋 Registration System

### GET /events/{eventId}/registration
Get registration information.

**Response:**
```json
{
  "event": {
    "id": "event_123",
    "title": "Tech Conference 2024"
  },
  "ticketTypes": [
    {
      "id": "ticket_general",
      "name": "General Admission",
      "description": "Standard event access",
      "price": 149.00,
      "currency": "USD",
      "available": 377,
      "total": 500,
      "saleEndDate": "2024-06-14T23:59:59Z",
      "features": ["All sessions", "Lunch included", "Networking events"]
    }
  ],
  "form": {
    "id": "form_123",
    "fields": [
      {
        "id": "dietary_restrictions",
        "type": "select",
        "label": "Dietary Restrictions",
        "required": false,
        "options": ["None", "Vegetarian", "Vegan", "Gluten-free"]
      }
    ]
  }
}
```

### POST /events/{eventId}/registration
Submit registration.

**Request:**
```json
{
  "attendeeInfo": {
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+1-555-123-4567",
    "company": "Tech Corp",
    "jobTitle": "Developer"
  },
  "tickets": [
    {
      "ticketTypeId": "ticket_general",
      "quantity": 1
    }
  ],
  "customFields": {
    "dietary_restrictions": "Vegetarian"
  },
  "promoCode": "EARLYBIRD"
}
```

### GET /registrations
Get user's registrations.

### GET /registrations/{registrationId}
Get specific registration details.

## 💳 Payment Processing

### POST /payments/process
Process payment for registration.

**Request:**
```json
{
  "registrationId": "reg_123",
  "paymentMethod": {
    "type": "credit_card",
    "cardToken": "card_token_from_stripe"
  },
  "amount": 149.00,
  "currency": "USD"
}
```

### GET /payments/{paymentId}
Get payment status.

## 📊 Analytics Endpoints

### GET /events/{eventId}/analytics
Get event analytics (organizer only).

**Response:**
```json
{
  "overview": {
    "totalRegistrations": 320,
    "checkedInCount": 285,
    "totalRevenue": 47680.00,
    "averageRating": 4.2
  },
  "attendance": {
    "bySession": [
      {
        "sessionId": "session_123",
        "title": "Keynote",
        "registered": 285,
        "attended": 245,
        "attendanceRate": 0.86
      }
    ],
    "timeline": [
      {
        "date": "2024-06-15",
        "checkins": 245
      }
    ]
  },
  "engagement": {
    "pollResponses": 1250,
    "qaQuestions": 85,
    "chatMessages": 450,
    "reactions": 890,
    "networkingConnections": 156
  },
  "demographics": {
    "byCompanySize": {
      "1-10": 45,
      "11-50": 89,
      "51-200": 112,
      "200+": 74
    },
    "byJobTitle": {
      "Developer": 145,
      "Product Manager": 67,
      "Designer": 43,
      "Executive": 29,
      "Other": 36
    }
  }
}
```

### GET /analytics/attendee/{attendeeId}
Get personal analytics for attendee.

## 🎮 Gamification

### GET /events/{eventId}/gamification
Get gamification data.

**Response:**
```json
{
  "userStats": {
    "totalPoints": 245,
    "currentLevel": {
      "level": 3,
      "name": "Active Networker",
      "pointsRequired": 200,
      "nextLevel": {
        "level": 4,
        "name": "Event Enthusiast",
        "pointsRequired": 400
      }
    },
    "achievements": [
      {
        "id": "ach_first_connection",
        "name": "First Connection",
        "description": "Made your first networking connection",
        "unlockedAt": "2024-06-15T10:15:00Z",
        "points": 50,
        "rarity": "common"
      }
    ]
  },
  "leaderboard": [
    {
      "rank": 1,
      "attendee": {
        "id": "att_789",
        "name": "Sarah Johnson",
        "company": "AI Corp"
      },
      "points": 450
    }
  ],
  "challenges": [
    {
      "id": "challenge_networker",
      "name": "Super Networker",
      "description": "Make 10 connections during the event",
      "progress": 7,
      "target": 10,
      "reward": 100,
      "endDate": "2024-06-16T18:00:00Z"
    }
  ]
}
```

### POST /gamification/actions
Record gamification action.

**Request:**
```json
{
  "action": "session_checkin",
  "sessionId": "session_123"
}
```

## 🔔 Notifications

### GET /notifications
Get user notifications.

### PUT /notifications/{notificationId}/read
Mark notification as read.

### POST /notifications/preferences
Update notification preferences.

## 🌐 WebSocket Endpoints

### Live Session Updates
**Endpoint:** `wss://ws.eventapp.com/sessions/{sessionId}/live`

**Events:**
- `reaction` - New reaction received
- `poll_update` - Poll responses updated
- `qa_question` - New Q&A question
- `attendee_count` - Attendance count changed

### Chat Messages
**Endpoint:** `wss://ws.eventapp.com/conversations/{conversationId}`

### Real-time Notifications
**Endpoint:** `wss://ws.eventapp.com/users/{userId}/notifications`

## 📁 File Upload

### POST /upload/images
Upload image files.

**Request:** Multipart form data
```
file: [image file]
type: "profile" | "event" | "gallery" | "resource"
```

**Response:**
```json
{
  "url": "https://cdn.eventapp.com/images/upload_123.jpg",
  "thumbnailUrl": "https://cdn.eventapp.com/images/thumb_123.jpg"
}
```

## ❌ Error Response Format

All API errors follow consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "timestamp": "2024-06-15T10:30:00Z",
  "requestId": "req_123456"
}
```

**Common Error Codes:**
- `AUTHENTICATION_REQUIRED` (401)
- `AUTHORIZATION_DENIED` (403)
- `RESOURCE_NOT_FOUND` (404)
- `VALIDATION_ERROR` (400)
- `RATE_LIMIT_EXCEEDED` (429)
- `INTERNAL_SERVER_ERROR` (500)

## 🔄 Rate Limiting

**Rate Limits:**
- Authentication: 10 requests/minute
- General API: 100 requests/minute
- File upload: 20 requests/minute
- WebSocket connections: 5 connections per user

**Headers:**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## 📝 API Versioning

API versions are specified in the URL path:
- Current: `/v1/`
- Future: `/v2/`

**Deprecation Policy:**
- 6-month notice for breaking changes
- Backwards compatibility maintained for one version
- Clear migration documentation provided

This API specification provides the foundation for a production-ready event planning platform with comprehensive feature coverage and scalable architecture.