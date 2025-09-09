import '../models/session.dart';
import '../models/attendee_profile.dart';
import 'database_service.dart';

class SessionService {
  final DatabaseService _databaseService = DatabaseService();

  Future<List<Session>> getEventSessions(String eventId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'startTime ASC',
    );

    return List.generate(maps.length, (i) {
      return Session.fromJson(maps[i]);
    });
  }

  Future<Session> createSession(Session session) async {
    final db = await _databaseService.database;
    final sessionWithId = session.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    
    final sessionData = sessionWithId.toJson();
    sessionData['speakerIds'] = sessionWithId.speakerIds.join(',');
    sessionData['attendeeIds'] = sessionWithId.attendeeIds.join(',');
    sessionData['tags'] = sessionWithId.tags.join(',');
    sessionData['customFields'] = sessionWithId.customFields.toString();

    await db.insert('sessions', sessionData);
    return sessionWithId;
  }

  Future<Session> updateSession(Session session) async {
    final db = await _databaseService.database;
    final updatedSession = session.copyWith(updatedAt: DateTime.now());
    
    final sessionData = updatedSession.toJson();
    sessionData['speakerIds'] = updatedSession.speakerIds.join(',');
    sessionData['attendeeIds'] = updatedSession.attendeeIds.join(',');
    sessionData['tags'] = updatedSession.tags.join(',');
    sessionData['customFields'] = updatedSession.customFields.toString();

    await db.update(
      'sessions',
      sessionData,
      where: 'id = ?',
      whereArgs: [session.id],
    );
    
    return updatedSession;
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await _databaseService.database;
    
    await db.transaction((txn) async {
      // Delete related polls
      await txn.delete(
        'polls',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      
      // Delete related Q&A questions
      await txn.delete(
        'qa_questions',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      
      // Delete related check-ins
      await txn.delete(
        'check_ins',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      
      // Delete the session
      await txn.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: [sessionId],
      );
    });
  }

  Future<Session?> getSessionById(String sessionId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final sessionData = maps.first;
      sessionData['speakerIds'] = (sessionData['speakerIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      sessionData['attendeeIds'] = (sessionData['attendeeIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      sessionData['tags'] = (sessionData['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList();
      return Session.fromJson(sessionData);
    }
    return null;
  }

  Future<bool> registerForSession(String sessionId, String attendeeId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return false;

    if (session.isFull || session.attendeeIds.contains(attendeeId)) {
      return false;
    }

    final updatedAttendees = [...session.attendeeIds, attendeeId];
    await updateSession(session.copyWith(attendeeIds: updatedAttendees));
    
    return true;
  }

  Future<bool> unregisterFromSession(String sessionId, String attendeeId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return false;

    final updatedAttendees = session.attendeeIds.where((id) => id != attendeeId).toList();
    await updateSession(session.copyWith(attendeeIds: updatedAttendees));
    
    return true;
  }

  Future<List<Session>> getSessionsByType(String eventId, SessionType type) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.type == type).toList();
  }

  Future<List<Session>> getSessionsByFormat(String eventId, SessionFormat format) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.format == format).toList();
  }

  Future<List<Session>> getTodaySessions(String eventId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => 
      session.startTime.isAfter(todayStart) && 
      session.startTime.isBefore(todayEnd)
    ).toList();
  }

  Future<List<Session>> getUpcomingSessions(String eventId, {int limitHours = 24}) async {
    final now = DateTime.now();
    final cutoffTime = now.add(Duration(hours: limitHours));

    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => 
      session.startTime.isAfter(now) && 
      session.startTime.isBefore(cutoffTime)
    ).toList();
  }

  Future<List<Session>> getUserRegisteredSessions(String eventId, String userId) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.attendeeIds.contains(userId)).toList();
  }

  Future<List<Session>> searchSessions(String eventId, String query) async {
    final sessions = await getEventSessions(eventId);
    final lowercaseQuery = query.toLowerCase();
    
    return sessions.where((session) {
      return session.title.toLowerCase().contains(lowercaseQuery) ||
             session.description.toLowerCase().contains(lowercaseQuery) ||
             session.location?.toLowerCase().contains(lowercaseQuery) == true ||
             session.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<Map<String, List<Session>>> groupSessionsByDay(String eventId) async {
    final sessions = await getEventSessions(eventId);
    final Map<String, List<Session>> groupedSessions = {};

    for (final session in sessions) {
      final dateKey = '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
      groupedSessions.putIfAbsent(dateKey, () => []).add(session);
    }

    // Sort sessions within each day
    for (final dayList in groupedSessions.values) {
      dayList.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return groupedSessions;
  }

  Future<List<Session>> getConflictingSessions(Session session, String eventId) async {
    final sessions = await getEventSessions(eventId);
    
    return sessions.where((other) => 
      other.id != session.id &&
      _sessionsOverlap(session, other)
    ).toList();
  }

  bool _sessionsOverlap(Session session1, Session session2) {
    return session1.startTime.isBefore(session2.endTime) &&
           session1.endTime.isAfter(session2.startTime);
  }

  Future<Map<String, dynamic>> getSessionStats(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return {};

    final db = await _databaseService.database;
    
    // Get attendance count
    final attendanceResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM check_ins WHERE sessionId = ?',
      [sessionId]
    );
    final attendance = attendanceResult.first['count'] as int;

    // Get poll count
    final pollsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM polls WHERE sessionId = ?',
      [sessionId]
    );
    final pollCount = pollsResult.first['count'] as int;

    // Get Q&A count
    final qaResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM qa_questions WHERE sessionId = ?',
      [sessionId]
    );
    final qaCount = qaResult.first['count'] as int;

    return {
      'registrations': session.attendeeIds.length,
      'attendance': attendance,
      'attendanceRate': session.attendeeIds.isNotEmpty 
          ? (attendance / session.attendeeIds.length * 100).round()
          : 0,
      'pollCount': pollCount,
      'qaCount': qaCount,
      'capacity': session.maxAttendees,
      'availableSpots': session.availableSpots,
      'isVirtual': session.isVirtual,
      'duration': session.duration.inMinutes,
    };
  }

  Future<bool> canUserJoinSession(String sessionId, String userId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return false;

    // Check if already registered
    if (session.attendeeIds.contains(userId)) return true;

    // Check if session requires registration and is full
    if (session.requiresRegistration && session.isFull) return false;

    // Check if session has already started (for virtual sessions)
    if (session.isVirtual && DateTime.now().isAfter(session.endTime)) {
      return false;
    }

    return true;
  }

  Future<List<Session>> getSpeakerSessions(String eventId, String speakerId) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.speakerIds.contains(speakerId)).toList();
  }

  Future<void> addSpeakerToSession(String sessionId, String speakerId) async {
    final session = await getSessionById(sessionId);
    if (session != null && !session.speakerIds.contains(speakerId)) {
      final updatedSpeakers = [...session.speakerIds, speakerId];
      await updateSession(session.copyWith(speakerIds: updatedSpeakers));
    }
  }

  Future<void> removeSpeakerFromSession(String sessionId, String speakerId) async {
    final session = await getSessionById(sessionId);
    if (session != null) {
      final updatedSpeakers = session.speakerIds.where((id) => id != speakerId).toList();
      await updateSession(session.copyWith(speakerIds: updatedSpeakers));
    }
  }

  Future<List<Session>> generatePersonalizedAgenda(String eventId, String userId) async {
    final registeredSessions = await getUserRegisteredSessions(eventId, userId);
    final allSessions = await getEventSessions(eventId);
    
    // Remove conflicts and create optimized schedule
    final personalizedAgenda = <Session>[];
    final occupiedTimes = <DateTime, DateTime>{};

    // First add registered sessions
    for (final session in registeredSessions) {
      if (!_hasTimeConflict(session, occupiedTimes)) {
        personalizedAgenda.add(session);
        occupiedTimes[session.startTime] = session.endTime;
      }
    }

    // Then suggest other sessions that don't conflict
    for (final session in allSessions) {
      if (!registeredSessions.contains(session) && 
          !_hasTimeConflict(session, occupiedTimes) &&
          personalizedAgenda.length < 10) { // Limit suggestions
        personalizedAgenda.add(session);
        occupiedTimes[session.startTime] = session.endTime;
      }
    }

    personalizedAgenda.sort((a, b) => a.startTime.compareTo(b.startTime));
    return personalizedAgenda;
  }

  bool _hasTimeConflict(Session session, Map<DateTime, DateTime> occupiedTimes) {
    for (final entry in occupiedTimes.entries) {
      if (_timesOverlap(session.startTime, session.endTime, entry.key, entry.value)) {
        return true;
      }
    }
    return false;
  }

  bool _timesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }
}