# 🎉 Event Planning App

A comprehensive event planning mobile application built with Flutter and Node.js, featuring real-time communication, networking capabilities, and robust admin management.

[![Flutter](https://img.shields.io/badge/Flutter-3.35.3-blue.svg)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-16+-green.svg)](https://nodejs.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-green.svg)](https://www.mongodb.com/atlas)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🚀 Overview

This event planning app provides a comprehensive solution for managing events from registration to post-event analytics. Built with Flutter and Dart, it offers a modern, scalable architecture with local SQLite database storage and real-time features.

## 📱 Key Features

### For Attendees
- **Smart Networking** - AI-powered attendee recommendations based on interests and goals
- **Live Engagement** - Real-time polling, Q&A, reactions, and chat during sessions
- **Digital Check-in** - QR code-based check-in with session attendance tracking
- **Personal Agenda** - Customizable schedule with session bookmarks and reminders
- **Social Features** - Community board, photo sharing, direct messaging, and group chats
- **Gamification** - Points, achievements, challenges, and leaderboards
- **Virtual Events** - Live streaming with interactive features and networking
- **Mobile Experience** - Native mobile app with offline capabilities

### For Organizers
- **Registration Management** - Advanced ticketing with multiple types, discounts, and approval workflows
- **Session Builder** - Drag-and-drop agenda creation with speaker management
- **Analytics Dashboard** - Real-time attendance, engagement, and revenue analytics
- **Announcements** - Multi-channel communication with priority levels
- **Sponsor Management** - Comprehensive exhibitor and sponsor tools
- **Website Builder** - Drag-and-drop event website creation
- **Payment Processing** - Integrated payment handling with transaction tracking
- **Content Management** - Photo gallery, document sharing, and resource management

## 🏗️ Architecture

### Project Structure
```
lib/
├── models/           # Data models and entities
├── services/         # Business logic and API services
├── screens/          # UI screens organized by feature
├── widgets/          # Reusable UI components
└── utils/           # Utilities and helpers
```

### Key Models
- **Event** - Core event information and settings
- **Attendee** - User profiles with professional information
- **Session** - Agenda items with speakers and resources
- **Registration** - Advanced registration with payments
- **Networking** - Connection and recommendation system
- **Analytics** - Comprehensive event metrics
- **Gamification** - Points, achievements, and challenges

## 🛠️ Technical Implementation

### Core Technologies
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **SQLite** - Local database storage
- **fl_chart** - Data visualization and analytics
- **Material Design** - UI/UX framework

### Architecture Patterns
- **Model-View-Service** - Clean separation of concerns
- **State Management** - StatefulWidget with setState
- **Service Layer** - Centralized business logic
- **Demo Data Generation** - Realistic test data for development

## 📊 Feature Breakdown

### 1. Networking System
**Files:** `models/networking.dart`, `services/networking_service.dart`, `screens/networking/`
- Smart attendee matching algorithm
- Connection requests and management
- Meeting scheduling and calendar integration
- Interest-based recommendations

### 2. Live Engagement
**Files:** `models/session.dart`, `screens/session/live_session_screen.dart`
- Real-time polling with multiple question types
- Live Q&A with moderation
- Audience reactions and feedback
- Chat integration during sessions

### 3. Registration System
**Files:** `models/registration.dart`, `services/registration_service.dart`, `screens/registration/`
- Multiple ticket types with flexible pricing
- Advanced discount code system
- Payment processing and transaction tracking
- Custom registration forms with conditional fields

### 4. Analytics Platform
**Files:** `models/analytics.dart`, `screens/analytics/`
- Real-time event metrics and KPIs
- Attendance tracking and heatmaps
- Engagement analytics with detailed reporting
- Revenue and registration analytics

### 5. Gamification Engine
**Files:** `models/gamification.dart`, `services/gamification_service.dart`
- Points system with configurable actions
- Achievement system with rarity levels
- Challenge creation and tracking
- Leaderboards and competition features

### 6. Virtual Event Platform
**Files:** `models/virtual_event.dart`, `screens/virtual_event/`
- Live streaming integration (placeholder for SDK)
- Interactive virtual sessions
- Breakout rooms and networking spaces
- Recording and playback capabilities

### 7. Website Builder
**Files:** `models/website.dart`, `screens/website/`
- Drag-and-drop page editor
- Template system with multiple themes
- SEO optimization tools
- Custom domain support

### 8. Content Management
**Files:** `models/photo.dart`, `services/photo_service.dart`
- Photo sharing and event gallery
- Document management and sharing
- Resource libraries for attendees
- Social media integration

## 📋 Implementation Status

### ✅ Completed Features
1. **Networking System** - Smart recommendations and connection management
2. **Live Polling & Q&A** - Real-time audience engagement
3. **Check-in System** - QR code-based attendance tracking
4. **Session Management** - Comprehensive agenda and speaker tools
5. **Attendee Profiles** - Professional networking profiles
6. **Messaging System** - 1:1 and group communication
7. **Community Board** - Social interaction platform
8. **Photo Sharing** - Event gallery and social features
9. **Announcements** - Multi-channel communication
10. **Analytics Dashboard** - Comprehensive reporting
11. **Gamification** - Points, achievements, and challenges
12. **Virtual Events** - Live streaming and interaction
13. **Sponsor Management** - Exhibitor and sponsor tools
14. **Website Builder** - Event website creation
15. **Advanced Registration** - Complete ticketing system

### 📱 Screen Navigation

```
Main App
├── Event List Screen
├── Event Detail Screen
│   ├── Sessions Tab
│   ├── Networking Tab
│   ├── Community Tab
│   └── More Tab
├── Session Screens
│   ├── Session Detail
│   ├── Live Session
│   └── Session Feedback
├── Networking Screens
│   ├── Attendee List
│   ├── Connection Requests
│   └── Meeting Scheduler
├── Community Screens
│   ├── Community Board
│   ├── Photo Gallery
│   └── Messaging
└── Organizer Screens
    ├── Registration Management
    ├── Analytics Dashboard
    ├── Website Builder
    └── Virtual Event Platform
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 2.17.0)
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the development server
4. The app will generate demo data automatically on first launch

### Demo Data
The app includes comprehensive demo data generation for:
- Sample events with realistic details
- Multiple attendee profiles with professional information
- Session schedules with speakers and content
- Registration data with various ticket types
- Analytics data with realistic metrics
- Networking connections and interactions

## 🔧 Configuration

### Database
- Uses SQLite for local data storage
- Automatic demo data generation
- Service layer abstraction for easy backend integration

### Services
Each major feature has a dedicated service class:
- `EventService` - Event management
- `AttendeeService` - User and profile management
- `SessionService` - Agenda and session handling
- `NetworkingService` - Connection and matching logic
- `RegistrationService` - Ticketing and payments
- `AnalyticsService` - Metrics and reporting
- `GamificationService` - Points and achievements
- `PhotoService` - Content and media management

## 📈 Scaling Considerations

### Backend Integration
The current implementation uses local SQLite storage with service layer abstraction. To scale to production:

1. **API Integration** - Replace service implementations with REST/GraphQL APIs
2. **Real-time Features** - Implement WebSocket connections for live features
3. **Cloud Storage** - Add cloud storage for photos and documents
4. **Push Notifications** - Integrate push notification services
5. **Payment Gateway** - Connect to payment processors (Stripe, PayPal)
6. **Video Streaming** - Integrate with streaming services (Agora, Zoom)

### Performance Optimization
- Implement pagination for large data sets
- Add caching layers for frequently accessed data
- Optimize image loading and caching
- Implement offline synchronization

## 🎯 Use Cases

### Corporate Events
- Conference management with speaker tracking
- Employee engagement and networking
- Training session management
- Sponsor integration and visibility

### Community Events
- Meetup organization and networking
- Workshop and seminar management
- Social interaction and community building
- Event promotion and marketing

### Virtual Events
- Online conference hosting
- Hybrid event management
- Interactive webinar platforms
- Remote networking facilitation

## 🤝 Contributing

This is a comprehensive event planning platform designed to demonstrate advanced Flutter development patterns and event management capabilities. The codebase follows best practices for maintainability and scalability.

## 📄 License

This project is a demonstration of event planning app capabilities and architectural patterns.

---

*Built with Flutter and designed to rival leading event platforms like Whova and EventMobi.*