import '../models/analytics.dart';
import '../models/event.dart';
import 'database_service.dart';
import 'community_service.dart';
import 'photo_gallery_service.dart';
import 'messaging_service.dart';
import 'announcement_service.dart';
import 'session_service.dart';
// import 'checkin_service.dart'; // Temporary comment to fix compilation
import 'polling_service.dart';
import 'profile_service.dart';

class AnalyticsService {
  final DatabaseService _databaseService = DatabaseService();
  final CommunityService _communityService = CommunityService();
  final PhotoGalleryService _photoService = PhotoGalleryService();
  final MessagingService _messagingService = MessagingService();
  final AnnouncementService _announcementService = AnnouncementService();
  final SessionService _sessionService = SessionService();
  // final CheckinService _checkinService = CheckinService(); // Temporary comment to fix compilation
  final PollingService _pollingService = PollingService();
  final ProfileService _profileService = ProfileService();

  Future<EventAnalytics> generateEventAnalytics(String eventId) async {
    final engagement = await _generateEngagementMetrics(eventId);
    final networking = await _generateNetworkingMetrics(eventId);
    final sessions = await _generateSessionMetrics(eventId);
    final keyMetrics = await _generateKeyMetrics(eventId);

    return EventAnalytics(
      eventId: eventId,
      generatedAt: DateTime.now(),
      engagement: engagement,
      networking: networking,
      sessions: sessions,
      customMetrics: await _generateCustomMetrics(eventId),
      keyMetrics: keyMetrics,
    );
  }

  Future<EngagementMetrics> _generateEngagementMetrics(String eventId) async {
    // In a real app, this would query user activity logs
    // For now, we'll calculate from available data
    
    final profiles = await _profileService.getAllProfiles();
    final communityStats = await _communityService.getCommunityStats(eventId);
    final photoStats = await _photoService.getGalleryStats(eventId);
    final announcementStats = await _announcementService.getAnnouncementStats(eventId);

    final totalUsers = profiles.length;
    final activeUsers = (totalUsers * 0.75).round(); // 75% active rate simulation
    final newUsers = (totalUsers * 0.25).round(); // 25% new users simulation

    final featureUsage = <String, int>{
      'community_posts': communityStats['totalPosts'] ?? 0,
      'photo_uploads': photoStats['totalPhotos'] ?? 0,
      'messages_sent': 150, // Simulated
      'announcements_read': announcementStats['totalReads'] ?? 0,
      'polls_participated': 45, // Simulated
      'sessions_attended': 200, // Simulated
      'check_ins': 180, // Simulated
      'profile_updates': 80, // Simulated
    };

    final timeSpentByFeature = <String, double>{
      'community_board': 45.5,
      'photo_gallery': 25.3,
      'messaging': 67.8,
      'sessions': 120.4,
      'networking': 38.7,
      'announcements': 15.2,
      'polls': 12.8,
    };

    return EngagementMetrics(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      newUsers: newUsers,
      averageSessionDuration: 28.5, // minutes
      totalSessions: (totalUsers * 3.2).round(), // Average 3.2 sessions per user
      totalPageViews: (totalUsers * 15.6).round(), // Average 15.6 page views per user
      engagementRate: 0.82, // 82% engagement rate
      featureUsage: featureUsage,
      timeSpentByFeature: timeSpentByFeature,
    );
  }

  Future<NetworkingMetrics> _generateNetworkingMetrics(String eventId) async {
    // In a real app, this would query actual networking data
    final profiles = await _profileService.getAllProfiles();
    final networkingProfiles = await _profileService.getNetworkingEnabledProfiles();
    
    final totalUsers = profiles.length;
    final networkingUsers = networkingProfiles.length;

    // Simulate networking connections
    final totalConnections = (networkingUsers * 8.5).round(); // Average 8.5 connections per networking user
    final newConnections = (totalConnections * 0.35).round(); // 35% new connections
    final totalMessages = (totalConnections * 4.2).round(); // Average 4.2 messages per connection
    
    final industryDistribution = await _profileService.getIndustryDistribution();
    final companyDistribution = await _profileService.getCompanyDistribution();
    
    return NetworkingMetrics(
      totalConnections: totalConnections,
      newConnections: newConnections,
      totalMessages: totalMessages,
      activeConversations: (totalMessages * 0.6).round(), // 60% of messages are in active conversations
      averageConnectionsPerUser: networkingUsers > 0 ? totalConnections / networkingUsers : 0.0,
      averageMessagesPerUser: networkingUsers > 0 ? totalMessages / networkingUsers : 0.0,
      totalProfileViews: (totalUsers * 12.3).round(), // Average 12.3 profile views per user
      connectionsByIndustry: industryDistribution,
      connectionsByCompany: companyDistribution,
      topNetworkers: _generateTopNetworkers(networkingUsers),
    );
  }

  Future<SessionMetrics> _generateSessionMetrics(String eventId) async {
    final sessions = await _sessionService.getEventSessions(eventId);
    final profiles = await _profileService.getAllProfiles();
    
    int totalAttendees = 0;
    int totalCheckIns = 0;
    double totalRating = 0.0;
    Map<String, int> attendanceBySession = {};
    Map<String, double> ratingsBySession = {};
    
    for (final session in sessions) {
      final attendance = session.attendeeIds.length;
      totalAttendees += attendance;
      attendanceBySession[session.title] = attendance;
      
      // Simulate check-ins (80% of registered attendees check in)
      final checkIns = (attendance * 0.8).round();
      totalCheckIns += checkIns;
      
      // Simulate ratings (4.0-4.8 range)
      final rating = 4.0 + (0.8 * (attendance / 100.0).clamp(0.0, 1.0));
      ratingsBySession[session.title] = rating;
      totalRating += rating;
    }

    final averageRating = sessions.isNotEmpty ? totalRating / sessions.length : 0.0;
    final averageAttendanceRate = sessions.isNotEmpty && profiles.isNotEmpty 
        ? (totalAttendees / (sessions.length * profiles.length)) 
        : 0.0;

    // Sort sessions by attendance and rating
    final sortedByAttendance = attendanceBySession.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedByRating = ratingsBySession.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SessionMetrics(
      totalSessions: sessions.length,
      totalAttendees: totalAttendees,
      averageAttendanceRate: averageAttendanceRate,
      totalCheckIns: totalCheckIns,
      averageRating: averageRating,
      attendanceBySession: attendanceBySession,
      ratingsBySession: ratingsBySession,
      topRatedSessions: sortedByRating.take(5).map((e) => e.key).toList(),
      mostAttendedSessions: sortedByAttendance.take(5).map((e) => e.key).toList(),
    );
  }

  Future<List<AnalyticsMetric>> _generateKeyMetrics(String eventId) async {
    final metrics = <AnalyticsMetric>[];
    final timestamp = DateTime.now();

    // Total Registrations
    final profiles = await _profileService.getAllProfiles();
    metrics.add(AnalyticsMetric(
      id: 'total_registrations',
      eventId: eventId,
      type: MetricType.attendance,
      name: 'Total Registrations',
      value: profiles.length.toDouble(),
      previousValue: (profiles.length * 0.85).toDouble(), // 15% growth simulation
      unit: 'users',
      timestamp: timestamp,
    ));

    // Session Attendance
    final sessions = await _sessionService.getEventSessions(eventId);
    final totalSessionAttendance = sessions.fold(0, (sum, session) => sum + session.attendeeIds.length);
    metrics.add(AnalyticsMetric(
      id: 'session_attendance',
      eventId: eventId,
      type: MetricType.sessions,
      name: 'Session Attendance',
      value: totalSessionAttendance.toDouble(),
      previousValue: (totalSessionAttendance * 0.92).toDouble(), // 8% growth simulation
      unit: 'attendees',
      timestamp: timestamp,
    ));

    // Community Engagement
    final communityStats = await _communityService.getCommunityStats(eventId);
    final engagementScore = ((communityStats['totalLikes'] ?? 0) + 
                            (communityStats['totalComments'] ?? 0)) / 
                           (communityStats['totalPosts'] ?? 1);
    metrics.add(AnalyticsMetric(
      id: 'community_engagement',
      eventId: eventId,
      type: MetricType.community,
      name: 'Community Engagement',
      value: engagementScore.toDouble(),
      previousValue: (engagementScore * 0.88).toDouble(), // 12% growth simulation
      unit: 'score',
      timestamp: timestamp,
    ));

    // Photo Sharing
    final photoStats = await _photoService.getGalleryStats(eventId);
    metrics.add(AnalyticsMetric(
      id: 'photo_uploads',
      eventId: eventId,
      type: MetricType.photos,
      name: 'Photo Uploads',
      value: (photoStats['totalPhotos'] ?? 0).toDouble(),
      previousValue: ((photoStats['totalPhotos'] ?? 0) * 0.75).toDouble(), // 25% growth simulation
      unit: 'photos',
      timestamp: timestamp,
    ));

    // Announcement Reach
    final announcementStats = await _announcementService.getAnnouncementStats(eventId);
    final reachRate = (announcementStats['totalReads'] ?? 0) / 
                     ((announcementStats['totalViews'] ?? 1).toDouble());
    metrics.add(AnalyticsMetric(
      id: 'announcement_reach',
      eventId: eventId,
      type: MetricType.announcements,
      name: 'Announcement Reach Rate',
      value: reachRate * 100, // Convert to percentage
      previousValue: (reachRate * 100) * 0.95, // 5% improvement simulation
      unit: '%',
      timestamp: timestamp,
    ));

    return metrics;
  }

  Future<Map<String, dynamic>> _generateCustomMetrics(String eventId) async {
    return {
      'app_downloads': 850,
      'push_notification_open_rate': 68.5,
      'average_session_length_minutes': 28.5,
      'daily_active_users': 320,
      'feature_adoption_rate': 82.3,
      'user_satisfaction_score': 4.6,
      'technical_issues_reported': 12,
      'support_tickets_resolved': 45,
    };
  }

  List<String> _generateTopNetworkers(int totalUsers) {
    // Simulate top networkers
    final topNetworkers = <String>[];
    for (int i = 1; i <= (totalUsers * 0.1).round().clamp(1, 10); i++) {
      topNetworkers.add('user_$i');
    }
    return topNetworkers;
  }

  Future<List<TimeSeriesData>> getEngagementTimeSeries(
    String eventId, 
    TimeRange timeRange,
    {DateTime? startDate, DateTime? endDate}
  ) async {
    final data = <TimeSeriesData>[];
    final now = DateTime.now();
    
    DateTime start;
    DateTime end = endDate ?? now;
    Duration interval;
    
    switch (timeRange) {
      case TimeRange.hourly:
        start = startDate ?? now.subtract(const Duration(hours: 24));
        interval = const Duration(hours: 1);
        break;
      case TimeRange.daily:
        start = startDate ?? now.subtract(const Duration(days: 7));
        interval = const Duration(days: 1);
        break;
      case TimeRange.weekly:
        start = startDate ?? now.subtract(const Duration(days: 30));
        interval = const Duration(days: 7);
        break;
      case TimeRange.monthly:
        start = startDate ?? now.subtract(const Duration(days: 365));
        interval = const Duration(days: 30);
        break;
      case TimeRange.custom:
        start = startDate ?? now.subtract(const Duration(days: 7));
        interval = Duration(
          milliseconds: (end.difference(start).inMilliseconds / 20).round()
        );
        break;
    }

    DateTime current = start;
    while (current.isBefore(end)) {
      // Simulate engagement data with some randomness
      final baseValue = 50.0;
      final randomFactor = (current.hour / 24.0) * 30; // Higher during day
      final weekendFactor = [6, 7].contains(current.weekday) ? 0.7 : 1.0; // Lower on weekends
      final value = (baseValue + randomFactor) * weekendFactor;
      
      data.add(TimeSeriesData(
        timestamp: current,
        value: value,
        metadata: {
          'dayOfWeek': current.weekday,
          'hour': current.hour,
        },
      ));
      
      current = current.add(interval);
    }
    
    return data;
  }

  Future<Map<String, dynamic>> getRealtimeStats(String eventId) async {
    // Simulate real-time statistics
    final now = DateTime.now();
    final baseUsers = 450;
    final variance = 50;
    final currentUsers = baseUsers + (variance * (now.millisecond / 1000.0)).round();
    
    return {
      'current_active_users': currentUsers,
      'sessions_this_hour': 23,
      'messages_this_hour': 156,
      'check_ins_this_hour': 34,
      'photos_uploaded_this_hour': 12,
      'announcements_sent_this_hour': 2,
      'polls_created_this_hour': 1,
      'new_connections_this_hour': 18,
      'last_updated': now.toIso8601String(),
    };
  }

  Future<List<AnalyticsMetric>> getMetricsByType(String eventId, MetricType type) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'analytics_metrics',
      where: 'eventId = ? AND type = ?',
      whereArgs: [eventId, type.name],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return AnalyticsMetric.fromJson(maps[i]);
    });
  }

  Future<void> recordMetric(AnalyticsMetric metric) async {
    final db = await _databaseService.database;
    await db.insert('analytics_metrics', metric.toJson());
  }

  Future<Map<String, dynamic>> getFeatureUsageAnalytics(String eventId) async {
    final communityStats = await _communityService.getCommunityStats(eventId);
    final photoStats = await _photoService.getGalleryStats(eventId);
    final announcementStats = await _announcementService.getAnnouncementStats(eventId);
    
    return {
      'community_board': {
        'total_posts': communityStats['totalPosts'] ?? 0,
        'total_likes': communityStats['totalLikes'] ?? 0,
        'total_comments': communityStats['totalComments'] ?? 0,
        'active_users': communityStats['activeUsers'] ?? 0,
        'engagement_rate': communityStats['engagementRate'] ?? 0.0,
      },
      'photo_gallery': {
        'total_photos': photoStats['totalPhotos'] ?? 0,
        'total_likes': photoStats['totalLikes'] ?? 0,
        'total_downloads': photoStats['totalDownloads'] ?? 0,
        'contributors': photoStats['totalContributors'] ?? 0,
        'albums_created': photoStats['totalAlbums'] ?? 0,
      },
      'announcements': {
        'total_announcements': announcementStats['totalAnnouncements'] ?? 0,
        'total_views': announcementStats['totalViews'] ?? 0,
        'total_reads': announcementStats['totalReads'] ?? 0,
        'read_rate': announcementStats['readRate'] ?? 0.0,
        'dismissal_rate': announcementStats['dismissalRate'] ?? 0.0,
      },
    };
  }

  Future<Map<String, dynamic>> getUserBehaviorAnalytics(String eventId) async {
    final profiles = await _profileService.getAllProfiles();
    final profileStats = await _profileService.getProfileStats();
    
    return {
      'total_users': profileStats['totalProfiles'] ?? 0,
      'profile_completion_rate': (profileStats['averageCompleteness'] ?? 0) / 100.0,
      'networking_enabled': profileStats['networkingEnabled'] ?? 0,
      'messaging_enabled': profileStats['messagingEnabled'] ?? 0,
      'popular_industries': await _profileService.getIndustryDistribution(),
      'popular_skills': await _profileService.getPopularSkills(),
      'popular_interests': await _profileService.getPopularInterests(),
    };
  }

  Future<Map<String, dynamic>> getSessionAnalytics(String eventId) async {
    final sessions = await _sessionService.getEventSessions(eventId);
    final sessionStats = <String, dynamic>{};
    
    int totalRegistrations = 0;
    int totalCapacity = 0;
    final Map<String, int> typeDistribution = {};
    final Map<String, int> formatDistribution = {};
    
    for (final session in sessions) {
      totalRegistrations += session.attendeeIds.length;
      totalCapacity += session.maxAttendees > 0 ? session.maxAttendees : session.attendeeIds.length;
      
      final typeKey = session.type.toString().split('.').last;
      typeDistribution[typeKey] = (typeDistribution[typeKey] ?? 0) + 1;
      
      final formatKey = session.format.toString().split('.').last;
      formatDistribution[formatKey] = (formatDistribution[formatKey] ?? 0) + 1;
    }
    
    return {
      'total_sessions': sessions.length,
      'total_registrations': totalRegistrations,
      'total_capacity': totalCapacity,
      'average_attendance_per_session': sessions.isNotEmpty ? totalRegistrations / sessions.length : 0.0,
      'capacity_utilization': totalCapacity > 0 ? totalRegistrations / totalCapacity : 0.0,
      'session_types': typeDistribution,
      'session_formats': formatDistribution,
    };
  }

  Future<Map<String, dynamic>> exportAnalyticsData(String eventId, {
    DateTime? startDate,
    DateTime? endDate,
    List<MetricType>? metricTypes,
  }) async {
    final analytics = await generateEventAnalytics(eventId);
    final featureUsage = await getFeatureUsageAnalytics(eventId);
    final userBehavior = await getUserBehaviorAnalytics(eventId);
    final sessionAnalytics = await getSessionAnalytics(eventId);
    final realtimeStats = await getRealtimeStats(eventId);
    
    return {
      'event_id': eventId,
      'generated_at': DateTime.now().toIso8601String(),
      'date_range': {
        'start': startDate?.toIso8601String(),
        'end': endDate?.toIso8601String(),
      },
      'overview': analytics.toJson(),
      'feature_usage': featureUsage,
      'user_behavior': userBehavior,
      'session_analytics': sessionAnalytics,
      'realtime_stats': realtimeStats,
      'export_metadata': {
        'total_records': 1000, // Simulated
        'processing_time_ms': 250, // Simulated
        'data_sources': [
          'user_profiles',
          'session_attendance',
          'community_posts',
          'photo_gallery',
          'messaging',
          'announcements',
          'polls',
          'check_ins',
        ],
      },
    };
  }
}