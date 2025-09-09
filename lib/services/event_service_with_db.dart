import '../models/event.dart';
import '../models/guest.dart';
import 'database_service.dart';

class EventService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Event>> getUserEvents(String userId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'organizerId = ?',
      whereArgs: [userId],
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  Future<Event> createEvent(Event event) async {
    final db = await _databaseService.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final eventWithId = event.copyWith(id: id);
    
    await db.insert('events', eventWithId.toJson());
    return eventWithId;
  }

  Future<Event> updateEvent(Event event) async {
    final db = await _databaseService.database;
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());
    
    await db.update(
      'events',
      updatedEvent.toJson(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    
    return updatedEvent;
  }

  Future<void> deleteEvent(String eventId) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
    
    await db.delete(
      'guests',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
  }

  Future<Event?> getEventById(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Event.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Guest>> getEventGuests(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'guests',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return Guest.fromJson(maps[i]);
    });
  }

  Future<void> addGuestToEvent(String eventId, Guest guest) async {
    final db = await _databaseService.database;
    final guestData = guest.toJson();
    guestData['eventId'] = eventId;
    
    await db.insert('guests', guestData);
  }

  Future<void> updateGuestRSVP(String eventId, String guestId, RSVPStatus status) async {
    final db = await _databaseService.database;
    
    await db.update(
      'guests',
      {
        'rsvpStatus': status.toString().split('.').last,
        'respondedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND eventId = ?',
      whereArgs: [guestId, eventId],
    );
  }

  Future<void> removeGuestFromEvent(String eventId, String guestId) async {
    final db = await _databaseService.database;
    
    await db.delete(
      'guests',
      where: 'id = ? AND eventId = ?',
      whereArgs: [guestId, eventId],
    );
  }

  Future<List<Event>> searchEvents(String userId, String query) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'organizerId = ? AND (title LIKE ? OR description LIKE ? OR location LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  Future<List<Event>> getEventsByCategory(String userId, EventCategory category) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'organizerId = ? AND category = ?',
      whereArgs: [userId, category.toString().split('.').last],
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  // Get all events (for admin)
  Future<List<Event>> getAllEvents() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      orderBy: 'dateTime DESC',
    );

    return List.generate(maps.length, (i) {
      return Event.fromJson(maps[i]);
    });
  }

  // Get events (simplified)
  Future<List<Event>> getEvents() async {
    return getAllEvents();
  }

  // Generate demo events
  Future<void> generateDemoEvents() async {
    final demoEvents = [
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

    for (final event in demoEvents) {
      await createEvent(event);
    }
  }
}