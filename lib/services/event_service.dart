import '../models/event.dart';
import '../models/guest.dart';
import 'api_service.dart';

class EventService {
  Future<List<Event>> getUserEvents(String userId) async {
    try {
      final response = await ApiService.get('/events/user/organized');
      
      if (response['success'] == true) {
        final List<dynamic> eventList = response['data'];
        
        return eventList.map((eventData) => _mapEventFromApi(eventData)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching user events: $e');
      return [];
    }
  }

  Future<Event> createEvent(Event event) async {
    try {
      final response = await ApiService.post('/events', {
        'title': event.title,
        'description': event.description,
        'dateTime': event.dateTime.toIso8601String(),
        'endDateTime': event.dateTime.add(const Duration(hours: 2)).toIso8601String(),
        'location': {
          'venue': event.location,
          'address': event.location,
          'city': 'Default City',
          'country': 'USA',
        },
        'capacity': event.maxAttendees,
        'price': 0,
        'category': _mapCategoryToApi(event.category),
        'isVirtual': false,
      });

      if (response['success'] == true) {
        return _mapEventFromApi(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create event');
      }
    } catch (e) {
      throw Exception('Failed to create event: ${e.toString()}');
    }
  }

  Future<Event> updateEvent(Event event) async {
    try {
      final response = await ApiService.put('/events/${event.id}', {
        'title': event.title,
        'description': event.description,
        'dateTime': event.dateTime.toIso8601String(),
        'capacity': event.maxAttendees,
      });

      if (response['success'] == true) {
        return _mapEventFromApi(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update event');
      }
    } catch (e) {
      throw Exception('Failed to update event: ${e.toString()}');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final response = await ApiService.delete('/events/$eventId');

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete event');
      }
    } catch (e) {
      throw Exception('Failed to delete event: ${e.toString()}');
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final response = await ApiService.get('/events/$eventId');
      
      if (response['success'] == true) {
        return _mapEventFromApi(response['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching event by ID: $e');
      return null;
    }
  }

  Future<List<Event>> searchEvents(String userId, String query) async {
    try {
      final response = await ApiService.get('/events/search?q=$query');
      
      if (response['success'] == true) {
        final List<dynamic> eventList = response['data'];
        return eventList.map((eventData) => _mapEventFromApi(eventData)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  Future<List<Event>> getEventsByCategory(String userId, EventCategory category) async {
    try {
      final categoryStr = _mapCategoryToApi(category);
      final response = await ApiService.get('/events/category/$categoryStr');
      
      if (response['success'] == true) {
        final List<dynamic> eventList = response['data'];
        return eventList.map((eventData) => _mapEventFromApi(eventData)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching events by category: $e');
      return [];
    }
  }

  // Get all events (for admin)
  Future<List<Event>> getAllEvents() async {
    try {
      final response = await ApiService.get('/events');
      
      if (response['success'] == true) {
        final List<dynamic> eventList = response['data'];
        return eventList.map((eventData) => _mapEventFromApi(eventData)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching all events: $e');
      return _generateDemoEvents();
    }
  }

  // Get events (simplified)
  Future<List<Event>> getEvents() async {
    return getAllEvents();
  }

  // Map API event data to Event model
  Event _mapEventFromApi(Map<String, dynamic> eventData) {
    return Event(
      id: eventData['_id'] ?? eventData['id'],
      title: eventData['title'] ?? 'Untitled Event',
      description: eventData['description'] ?? '',
      dateTime: DateTime.parse(eventData['dateTime'] ?? eventData['dateTime'] ?? DateTime.now().toIso8601String()),
      location: eventData['location'] is Map 
          ? eventData['location']['venue'] ?? 'Unknown Location'
          : eventData['location'] ?? 'Unknown Location',
      organizerId: eventData['organizer'] is Map 
          ? eventData['organizer']['_id']
          : eventData['organizer'] ?? 'unknown',
      category: _mapCategoryFromApi(eventData['category'] ?? 'other'),
      maxAttendees: eventData['capacity'] ?? 100,
      currentAttendees: eventData['attendees'] is List 
          ? (eventData['attendees'] as List).length
          : 0,
      price: (eventData['price'] ?? 0).toDouble(),
      tags: eventData['tags'] is List 
          ? List<String>.from(eventData['tags'])
          : [],
      isPublic: eventData['status'] != 'draft',
      createdAt: eventData['createdAt'] != null 
          ? DateTime.parse(eventData['createdAt'])
          : DateTime.now(),
      updatedAt: eventData['updatedAt'] != null 
          ? DateTime.parse(eventData['updatedAt'])
          : DateTime.now(),
      status: _mapStatusFromApi(eventData['status'] ?? 'draft'),
      isVirtual: eventData['isVirtual'] ?? false,
    );
  }

  // Map Flutter category to API category
  String _mapCategoryToApi(EventCategory category) {
    switch (category) {
      case EventCategory.conference:
        return 'conference';
      case EventCategory.workshop:
        return 'workshop';
      case EventCategory.networking:
        return 'networking';
      case EventCategory.seminar:
        return 'seminar';
      case EventCategory.social:
        return 'social';
      case EventCategory.business:
        return 'other';
      case EventCategory.sports:
        return 'other';
      case EventCategory.arts:
        return 'other';
      case EventCategory.education:
        return 'seminar';
      case EventCategory.community:
        return 'other';
      default:
        return 'other';
    }
  }

  // Map API category to Flutter category
  EventCategory _mapCategoryFromApi(String category) {
    switch (category.toLowerCase()) {
      case 'conference':
        return EventCategory.conference;
      case 'workshop':
        return EventCategory.workshop;
      case 'networking':
        return EventCategory.networking;
      case 'seminar':
        return EventCategory.seminar;
      case 'social':
        return EventCategory.social;
      default:
        return EventCategory.business;
    }
  }

  // Map API status to Flutter status
  EventStatus _mapStatusFromApi(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return EventStatus.active;
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'draft':
      default:
        return EventStatus.draft;
    }
  }

  // Generate demo events as fallback
  List<Event> _generateDemoEvents() {
    return [
      Event(
        id: 'demo_1',
        title: 'Tech Conference 2024',
        description: 'Annual technology conference featuring latest innovations',
        dateTime: DateTime.now().add(const Duration(days: 30)),
        location: 'Convention Center',
        organizerId: 'demo_user',
        category: EventCategory.conference,
        maxAttendees: 500,
        currentAttendees: 0,
        isPublic: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Event(
        id: 'demo_2',
        title: 'Summer Music Festival',
        description: 'Three-day music festival with top artists',
        dateTime: DateTime.now().add(const Duration(days: 60)),
        location: 'City Park',
        organizerId: 'demo_user',
        category: EventCategory.social,
        maxAttendees: 1000,
        currentAttendees: 0,
        isPublic: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Event(
        id: 'demo_3',
        title: 'Corporate Training Workshop',
        description: 'Professional development and skills training',
        dateTime: DateTime.now().add(const Duration(days: 15)),
        location: 'Business Center',
        organizerId: 'demo_user',
        category: EventCategory.business,
        maxAttendees: 50,
        currentAttendees: 0,
        isPublic: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Generate demo events
  Future<void> generateDemoEvents() async {
    // No longer needed as we get data from API
  }

  // Guest management (simplified)
  Future<List<Guest>> getEventGuests(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  Future<void> addGuestToEvent(String eventId, Guest guest) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> updateGuestRSVP(String eventId, String guestId, RSVPStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> removeGuestFromEvent(String eventId, String guestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}