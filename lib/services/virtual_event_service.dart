import '../models/virtual_event.dart';
import '../models/event.dart';
import 'database_service.dart';

class VirtualEventService {
  final DatabaseService _databaseService = DatabaseService();

  // Session Management
  Future<List<VirtualSession>> getEventSessions(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'virtual_sessions',
      where: 'eventId = ?',
      whereArgs: [eventId],
      orderBy: 'scheduledStart ASC',
    );

    return maps.map((map) => VirtualSession.fromJson(map)).toList();
  }

  Future<VirtualSession?> getSession(String sessionId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'virtual_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    return maps.isNotEmpty ? VirtualSession.fromJson(maps.first) : null;
  }

  Future<List<VirtualSession>> getLiveSessions(String eventId) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.isLive).toList();
  }

  Future<List<VirtualSession>> getUpcomingSessions(String eventId) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.isUpcoming).toList();
  }

  Future<List<VirtualSession>> getSessionsByType(String eventId, StreamType type) async {
    final sessions = await getEventSessions(eventId);
    return sessions.where((session) => session.type == type).toList();
  }

  Future<VirtualSession> createSession(VirtualSession session) async {
    final db = await _databaseService.database;
    await db.insert('virtual_sessions', session.toJson());
    return session;
  }

  Future<void> updateSession(VirtualSession session) async {
    final db = await _databaseService.database;
    await db.update(
      'virtual_sessions',
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await _databaseService.database;
    
    // Delete related data
    await Future.wait([
      db.delete('stream_messages', where: 'sessionId = ?', whereArgs: [sessionId]),
      db.delete('breakout_rooms', where: 'sessionId = ?', whereArgs: [sessionId]),
      db.delete('stream_reactions', where: 'sessionId = ?', whereArgs: [sessionId]),
      db.delete('viewer_sessions', where: 'sessionId = ?', whereArgs: [sessionId]),
    ]);
    
    // Delete session
    await db.delete('virtual_sessions', where: 'id = ?', whereArgs: [sessionId]);
  }

  // Stream Status Management
  Future<void> startStream(String sessionId) async {
    final session = await getSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        status: StreamStatus.live,
        actualStart: DateTime.now(),
      );
      await updateSession(updatedSession);
    }
  }

  Future<void> endStream(String sessionId) async {
    final session = await getSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(
        status: StreamStatus.ended,
        actualEnd: DateTime.now(),
      );
      await updateSession(updatedSession);
    }
  }

  Future<void> updateStreamStatus(String sessionId, StreamStatus status) async {
    final session = await getSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(status: status);
      await updateSession(updatedSession);
    }
  }

  // Viewer Management
  Future<void> joinSession(String sessionId, String userId, ViewerRole role) async {
    final db = await _databaseService.database;
    
    // Add user to session attendees
    final session = await getSession(sessionId);
    if (session != null && !session.attendeeIds.contains(userId)) {
      final updatedSession = session.copyWith(
        attendeeIds: [...session.attendeeIds, userId],
      );
      await updateSession(updatedSession);
    }
    
    // Create viewer session
    final viewerSession = ViewerSession(
      userId: userId,
      sessionId: sessionId,
      joinedAt: DateTime.now(),
      watchTime: Duration.zero,
      role: role,
      quality: StreamQuality.auto,
    );
    
    await db.insert('viewer_sessions', viewerSession.toJson());
  }

  Future<void> leaveSession(String sessionId, String userId) async {
    final db = await _databaseService.database;
    
    // Update viewer session with leave time
    await db.update(
      'viewer_sessions',
      {'leftAt': DateTime.now().toIso8601String()},
      where: 'sessionId = ? AND userId = ? AND leftAt IS NULL',
      whereArgs: [sessionId, userId],
    );
    
    // Remove user from session attendees
    final session = await getSession(sessionId);
    if (session != null) {
      final updatedAttendees = session.attendeeIds.where((id) => id != userId).toList();
      final updatedSession = session.copyWith(attendeeIds: updatedAttendees);
      await updateSession(updatedSession);
    }
  }

  Future<List<ViewerSession>> getSessionViewers(String sessionId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'viewer_sessions',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'joinedAt DESC',
    );

    return maps.map((map) => ViewerSession.fromJson(map)).toList();
  }

  Future<List<ViewerSession>> getCurrentViewers(String sessionId) async {
    final viewers = await getSessionViewers(sessionId);
    return viewers.where((viewer) => viewer.isCurrentlyWatching).toList();
  }

  // Chat & Messaging
  Future<void> sendMessage(StreamMessage message) async {
    final db = await _databaseService.database;
    await db.insert('stream_messages', message.toJson());
  }

  Future<List<StreamMessage>> getSessionMessages(String sessionId, {int limit = 100}) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stream_messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => StreamMessage.fromJson(map)).toList().reversed.toList();
  }

  Future<void> deleteMessage(String messageId) async {
    final db = await _databaseService.database;
    await db.delete('stream_messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<void> pinMessage(String messageId, bool pin) async {
    final db = await _databaseService.database;
    await db.update(
      'stream_messages',
      {'isPinned': pin},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<StreamMessage>> getPinnedMessages(String sessionId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stream_messages',
      where: 'sessionId = ? AND isPinned = 1',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => StreamMessage.fromJson(map)).toList();
  }

  // Reactions
  Future<void> addReaction(StreamReaction reaction) async {
    final db = await _databaseService.database;
    await db.insert('stream_reactions', reaction.toJson());
  }

  Future<List<StreamReaction>> getRecentReactions(String sessionId, {Duration? since}) async {
    final db = await _databaseService.database;
    final cutoffTime = since != null 
        ? DateTime.now().subtract(since).toIso8601String()
        : DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'stream_reactions',
      where: 'sessionId = ? AND timestamp > ?',
      whereArgs: [sessionId, cutoffTime],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => StreamReaction.fromJson(map)).toList();
  }

  Future<Map<String, int>> getReactionCounts(String sessionId, {Duration? timeframe}) async {
    final reactions = await getRecentReactions(sessionId, since: timeframe);
    final counts = <String, int>{};
    
    for (final reaction in reactions) {
      counts[reaction.reaction] = (counts[reaction.reaction] ?? 0) + 1;
    }
    
    return counts;
  }

  // Breakout Rooms
  Future<BreakoutRoom> createBreakoutRoom(BreakoutRoom room) async {
    final db = await _databaseService.database;
    await db.insert('breakout_rooms', room.toJson());
    return room;
  }

  Future<List<BreakoutRoom>> getBreakoutRooms(String sessionId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'breakout_rooms',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'createdAt ASC',
    );

    return maps.map((map) => BreakoutRoom.fromJson(map)).toList();
  }

  Future<void> joinBreakoutRoom(String roomId, String userId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'breakout_rooms',
      where: 'id = ?',
      whereArgs: [roomId],
    );

    if (maps.isNotEmpty) {
      final room = BreakoutRoom.fromJson(maps.first);
      if (!room.isFull && !room.participantIds.contains(userId)) {
        final updatedRoom = BreakoutRoom(
          id: room.id,
          sessionId: room.sessionId,
          name: room.name,
          description: room.description,
          maxParticipants: room.maxParticipants,
          participantIds: [...room.participantIds, userId],
          moderatorIds: room.moderatorIds,
          createdAt: room.createdAt,
          isActive: room.isActive,
          settings: room.settings,
        );
        
        await db.update('breakout_rooms', updatedRoom.toJson(), where: 'id = ?', whereArgs: [roomId]);
      }
    }
  }

  Future<void> leaveBreakoutRoom(String roomId, String userId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'breakout_rooms',
      where: 'id = ?',
      whereArgs: [roomId],
    );

    if (maps.isNotEmpty) {
      final room = BreakoutRoom.fromJson(maps.first);
      final updatedParticipants = room.participantIds.where((id) => id != userId).toList();
      
      final updatedRoom = BreakoutRoom(
        id: room.id,
        sessionId: room.sessionId,
        name: room.name,
        description: room.description,
        maxParticipants: room.maxParticipants,
        participantIds: updatedParticipants,
        moderatorIds: room.moderatorIds,
        createdAt: room.createdAt,
        isActive: room.isActive,
        settings: room.settings,
      );
      
      await db.update('breakout_rooms', updatedRoom.toJson(), where: 'id = ?', whereArgs: [roomId]);
    }
  }

  Future<void> deleteBreakoutRoom(String roomId) async {
    final db = await _databaseService.database;
    await db.delete('breakout_rooms', where: 'id = ?', whereArgs: [roomId]);
  }

  // Settings Management
  Future<VirtualEventSettings> getEventSettings(String eventId) async {
    final db = await _databaseService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'virtual_event_settings',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );

    if (maps.isNotEmpty) {
      return VirtualEventSettings.fromJson(maps.first);
    } else {
      // Create default settings
      final defaultSettings = VirtualEventSettings(eventId: eventId);
      await saveEventSettings(defaultSettings);
      return defaultSettings;
    }
  }

  Future<void> saveEventSettings(VirtualEventSettings settings) async {
    final db = await _databaseService.database;
    
    final existing = await db.query(
      'virtual_event_settings',
      where: 'eventId = ?',
      whereArgs: [settings.eventId],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'virtual_event_settings',
        settings.toJson(),
        where: 'eventId = ?',
        whereArgs: [settings.eventId],
      );
    } else {
      await db.insert('virtual_event_settings', settings.toJson());
    }
  }

  // Analytics & Reporting
  Future<Map<String, dynamic>> getSessionAnalytics(String sessionId) async {
    final session = await getSession(sessionId);
    final viewers = await getSessionViewers(sessionId);
    final messages = await getSessionMessages(sessionId);
    final reactions = await getRecentReactions(sessionId, since: const Duration(hours: 24));
    
    if (session == null) return {};

    final totalViewers = viewers.length;
    final currentViewers = viewers.where((v) => v.isCurrentlyWatching).length;
    final averageWatchTime = viewers.isNotEmpty 
        ? viewers.map((v) => v.sessionDuration.inMinutes).reduce((a, b) => a + b) / viewers.length
        : 0.0;
    
    final engagementRate = totalViewers > 0 
        ? ((messages.length + reactions.length) / totalViewers) * 100
        : 0.0;

    return {
      'sessionId': sessionId,
      'title': session.title,
      'status': session.status.name,
      'totalViewers': totalViewers,
      'currentViewers': currentViewers,
      'peakViewers': session.attendeeIds.length, // This would be tracked separately in a real app
      'averageWatchTime': averageWatchTime,
      'totalMessages': messages.length,
      'totalReactions': reactions.length,
      'engagementRate': engagementRate,
      'duration': session.duration.inMinutes,
      'actualDuration': session.actualEnd != null && session.actualStart != null
          ? session.actualEnd!.difference(session.actualStart!).inMinutes
          : null,
    };
  }

  Future<Map<String, dynamic>> getEventAnalytics(String eventId) async {
    final sessions = await getEventSessions(eventId);
    final analytics = <Map<String, dynamic>>[];
    
    for (final session in sessions) {
      analytics.add(await getSessionAnalytics(session.id));
    }

    final totalSessions = sessions.length;
    final liveSessions = sessions.where((s) => s.isLive).length;
    final completedSessions = sessions.where((s) => s.hasEnded).length;
    
    final totalViewers = analytics.fold(0, (sum, a) => sum + (a['totalViewers'] as int? ?? 0));
    final totalMessages = analytics.fold(0, (sum, a) => sum + (a['totalMessages'] as int? ?? 0));
    final totalReactions = analytics.fold(0, (sum, a) => sum + (a['totalReactions'] as int? ?? 0));
    
    final averageEngagement = analytics.isNotEmpty
        ? analytics.map((a) => a['engagementRate'] as double? ?? 0.0).reduce((a, b) => a + b) / analytics.length
        : 0.0;

    return {
      'eventId': eventId,
      'totalSessions': totalSessions,
      'liveSessions': liveSessions,
      'completedSessions': completedSessions,
      'totalViewers': totalViewers,
      'totalMessages': totalMessages,
      'totalReactions': totalReactions,
      'averageEngagement': averageEngagement,
      'sessionsAnalytics': analytics,
    };
  }

  // Utility methods for generating demo data
  Future<void> generateDemoSessions(String eventId) async {
    final now = DateTime.now();
    final demoSessions = [
      VirtualSession(
        id: 'demo_keynote_1',
        eventId: eventId,
        title: 'Opening Keynote: The Future of Technology',
        description: 'Join us for an inspiring keynote about emerging technologies and their impact on society.',
        type: StreamType.keynote,
        status: StreamStatus.scheduled,
        scheduledStart: now.add(const Duration(hours: 1)),
        scheduledEnd: now.add(const Duration(hours: 2)),
        streamUrl: 'https://example.com/stream/keynote1',
        thumbnailUrl: 'https://example.com/thumbnails/keynote1.jpg',
        speakerIds: ['speaker_1'],
        moderatorIds: ['mod_1'],
        enabledInteractions: ['chat', 'poll', 'qa', 'reaction'],
        tags: ['keynote', 'technology', 'future'],
      ),
      VirtualSession(
        id: 'demo_workshop_1',
        eventId: eventId,
        title: 'Interactive Workshop: Building Mobile Apps',
        description: 'Hands-on workshop covering mobile app development fundamentals.',
        type: StreamType.workshop,
        status: StreamStatus.live,
        scheduledStart: now.subtract(const Duration(minutes: 30)),
        scheduledEnd: now.add(const Duration(hours: 1, minutes: 30)),
        actualStart: now.subtract(const Duration(minutes: 25)),
        streamUrl: 'https://example.com/stream/workshop1',
        thumbnailUrl: 'https://example.com/thumbnails/workshop1.jpg',
        speakerIds: ['speaker_2', 'speaker_3'],
        moderatorIds: ['mod_2'],
        enabledInteractions: ['chat', 'screen_share', 'breakout_room'],
        tags: ['workshop', 'mobile', 'development'],
        attendeeIds: ['user1', 'user2', 'user3', 'user4', 'user5'],
        maxAttendees: 50,
      ),
      VirtualSession(
        id: 'demo_panel_1',
        eventId: eventId,
        title: 'Panel Discussion: Industry Leaders',
        description: 'Expert panel discussing current trends and future predictions.',
        type: StreamType.panel,
        status: StreamStatus.ended,
        scheduledStart: now.subtract(const Duration(hours: 2)),
        scheduledEnd: now.subtract(const Duration(hours: 1)),
        actualStart: now.subtract(const Duration(hours: 2, minutes: 5)),
        actualEnd: now.subtract(const Duration(minutes: 55)),
        streamUrl: 'https://example.com/stream/panel1',
        recordingUrl: 'https://example.com/recordings/panel1.mp4',
        thumbnailUrl: 'https://example.com/thumbnails/panel1.jpg',
        speakerIds: ['speaker_4', 'speaker_5', 'speaker_6'],
        moderatorIds: ['mod_3'],
        enabledInteractions: ['chat', 'qa', 'reaction'],
        tags: ['panel', 'discussion', 'industry'],
        attendeeIds: ['user1', 'user2', 'user3', 'user7', 'user8', 'user9'],
      ),
      VirtualSession(
        id: 'demo_networking_1',
        eventId: eventId,
        title: 'Virtual Networking Hour',
        description: 'Connect with fellow attendees in breakout rooms.',
        type: StreamType.networking,
        status: StreamStatus.scheduled,
        scheduledStart: now.add(const Duration(hours: 3)),
        scheduledEnd: now.add(const Duration(hours: 4)),
        streamUrl: 'https://example.com/stream/networking1',
        thumbnailUrl: 'https://example.com/thumbnails/networking1.jpg',
        moderatorIds: ['mod_4', 'mod_5'],
        enabledInteractions: ['chat', 'breakout_room', 'reaction'],
        tags: ['networking', 'social', 'connections'],
        maxAttendees: 200,
      ),
      VirtualSession(
        id: 'demo_qa_1',
        eventId: eventId,
        title: 'Ask the Experts: Q&A Session',
        description: 'Get your questions answered by industry experts.',
        type: StreamType.qa_session,
        status: StreamStatus.scheduled,
        scheduledStart: now.add(const Duration(hours: 5)),
        scheduledEnd: now.add(const Duration(hours: 6)),
        streamUrl: 'https://example.com/stream/qa1',
        thumbnailUrl: 'https://example.com/thumbnails/qa1.jpg',
        speakerIds: ['speaker_7', 'speaker_8'],
        moderatorIds: ['mod_6'],
        enabledInteractions: ['qa', 'reaction'],
        tags: ['qa', 'experts', 'questions'],
      ),
    ];

    for (final session in demoSessions) {
      await createSession(session);
    }
  }

  // Helper method to generate demo messages for testing
  Future<void> generateDemoMessages(String sessionId, String sessionTitle) async {
    final now = DateTime.now();
    final demoMessages = [
      StreamMessage(
        id: 'msg_${sessionId}_1',
        sessionId: sessionId,
        userId: 'user1',
        userName: 'Alice Johnson',
        message: 'Great session! Really enjoying the content so far.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: InteractionType.chat,
      ),
      StreamMessage(
        id: 'msg_${sessionId}_2',
        sessionId: sessionId,
        userId: 'user2',
        userName: 'Bob Smith',
        message: 'Can you share the slides after the presentation?',
        timestamp: now.subtract(const Duration(minutes: 12)),
        type: InteractionType.chat,
      ),
      StreamMessage(
        id: 'msg_${sessionId}_3',
        sessionId: sessionId,
        userId: 'moderator1',
        userName: 'Event Moderator',
        message: 'Welcome everyone! Please feel free to ask questions in the chat.',
        timestamp: now.subtract(const Duration(minutes: 20)),
        type: InteractionType.chat,
        isFromModerator: true,
        isPinned: true,
      ),
      StreamMessage(
        id: 'msg_${sessionId}_4',
        sessionId: sessionId,
        userId: 'user3',
        userName: 'Carol Davis',
        message: 'This is exactly what I was looking for. Thank you! 🎉',
        timestamp: now.subtract(const Duration(minutes: 8)),
        type: InteractionType.chat,
      ),
      StreamMessage(
        id: 'msg_${sessionId}_5',
        sessionId: sessionId,
        userId: 'user4',
        userName: 'David Wilson',
        message: 'How do we access the breakout rooms?',
        timestamp: now.subtract(const Duration(minutes: 5)),
        type: InteractionType.chat,
      ),
    ];

    for (final message in demoMessages) {
      await sendMessage(message);
    }
  }
}