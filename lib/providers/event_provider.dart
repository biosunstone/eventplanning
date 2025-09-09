import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/guest.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  Event? _currentEvent;
  bool _isLoading = false;
  String? _error;

  List<Event> get events => _events;
  Event? get currentEvent => _currentEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Event> get upcomingEvents {
    final now = DateTime.now();
    return _events
        .where((event) => event.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<Event> get pastEvents {
    final now = DateTime.now();
    return _events
        .where((event) => event.dateTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Future<void> loadEvents(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _events = await _eventService.getUserEvents(userId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> createEvent(Event event) async {
    _setLoading(true);
    _clearError();

    try {
      final createdEvent = await _eventService.createEvent(event);
      _events.add(createdEvent);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEvent(Event event) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedEvent = await _eventService.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = updatedEvent;
      }
      if (_currentEvent?.id == event.id) {
        _currentEvent = updatedEvent;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      await _eventService.deleteEvent(eventId);
      _events.removeWhere((event) => event.id == eventId);
      if (_currentEvent?.id == eventId) {
        _currentEvent = null;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadEventDetails(String eventId) async {
    _setLoading(true);
    _clearError();

    try {
      _currentEvent = await _eventService.getEventById(eventId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> addGuest(String eventId, Guest guest) async {
    try {
      await _eventService.addGuestToEvent(eventId, guest);
      if (_currentEvent?.id == eventId) {
        await loadEventDetails(eventId);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> updateGuestRSVP(String eventId, String guestId, RSVPStatus status) async {
    try {
      await _eventService.updateGuestRSVP(eventId, guestId, status);
      if (_currentEvent?.id == eventId) {
        await loadEventDetails(eventId);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void setCurrentEvent(Event? event) {
    _currentEvent = event;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}