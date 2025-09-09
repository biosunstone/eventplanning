enum MetricType {
  attendance,
  engagement,
  networking,
  polls,
  checkins,
  photos,
  messages,
  announcements,
  sessions,
  community,
}

enum TimeRange {
  hourly,
  daily,
  weekly,
  monthly,
  custom,
}

class AnalyticsMetric {
  final String id;
  final String eventId;
  final MetricType type;
  final String name;
  final double value;
  final double? previousValue;
  final String unit;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AnalyticsMetric({
    required this.id,
    required this.eventId,
    required this.type,
    required this.name,
    required this.value,
    this.previousValue,
    required this.unit,
    required this.timestamp,
    this.metadata = const {},
  });

  double? get changePercentage {
    if (previousValue == null || previousValue == 0) return null;
    return ((value - previousValue!) / previousValue!) * 100;
  }

  bool get isIncreasing => changePercentage != null && changePercentage! > 0;
  bool get isDecreasing => changePercentage != null && changePercentage! < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'type': type.name,
      'name': name,
      'value': value,
      'previousValue': previousValue,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata.toString(),
    };
  }

  factory AnalyticsMetric.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetric(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      type: MetricType.values.firstWhere((e) => e.name == json['type']),
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
      previousValue: json['previousValue'] != null ? (json['previousValue'] as num).toDouble() : null,
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
    );
  }
}

class TimeSeriesData {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> metadata;

  TimeSeriesData({
    required this.timestamp,
    required this.value,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'metadata': metadata.toString(),
    };
  }

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) {
    return TimeSeriesData(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
    );
  }
}

class EngagementMetrics {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final double averageSessionDuration;
  final int totalSessions;
  final int totalPageViews;
  final double engagementRate;
  final Map<String, int> featureUsage;
  final Map<String, double> timeSpentByFeature;

  EngagementMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.averageSessionDuration,
    required this.totalSessions,
    required this.totalPageViews,
    required this.engagementRate,
    required this.featureUsage,
    required this.timeSpentByFeature,
  });

  double get userRetentionRate => totalUsers > 0 ? (activeUsers / totalUsers) : 0.0;
  double get newUserRate => totalUsers > 0 ? (newUsers / totalUsers) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'newUsers': newUsers,
      'averageSessionDuration': averageSessionDuration,
      'totalSessions': totalSessions,
      'totalPageViews': totalPageViews,
      'engagementRate': engagementRate,
      'featureUsage': featureUsage,
      'timeSpentByFeature': timeSpentByFeature,
    };
  }

  factory EngagementMetrics.fromJson(Map<String, dynamic> json) {
    return EngagementMetrics(
      totalUsers: json['totalUsers'] as int,
      activeUsers: json['activeUsers'] as int,
      newUsers: json['newUsers'] as int,
      averageSessionDuration: (json['averageSessionDuration'] as num).toDouble(),
      totalSessions: json['totalSessions'] as int,
      totalPageViews: json['totalPageViews'] as int,
      engagementRate: (json['engagementRate'] as num).toDouble(),
      featureUsage: Map<String, int>.from(json['featureUsage']),
      timeSpentByFeature: Map<String, double>.from(json['timeSpentByFeature']),
    );
  }
}

class NetworkingMetrics {
  final int totalConnections;
  final int newConnections;
  final int totalMessages;
  final int activeConversations;
  final double averageConnectionsPerUser;
  final double averageMessagesPerUser;
  final int totalProfileViews;
  final Map<String, int> connectionsByIndustry;
  final Map<String, int> connectionsByCompany;
  final List<String> topNetworkers;

  NetworkingMetrics({
    required this.totalConnections,
    required this.newConnections,
    required this.totalMessages,
    required this.activeConversations,
    required this.averageConnectionsPerUser,
    required this.averageMessagesPerUser,
    required this.totalProfileViews,
    required this.connectionsByIndustry,
    required this.connectionsByCompany,
    required this.topNetworkers,
  });

  double get messagingActivityRate => totalConnections > 0 ? (totalMessages / totalConnections) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalConnections': totalConnections,
      'newConnections': newConnections,
      'totalMessages': totalMessages,
      'activeConversations': activeConversations,
      'averageConnectionsPerUser': averageConnectionsPerUser,
      'averageMessagesPerUser': averageMessagesPerUser,
      'totalProfileViews': totalProfileViews,
      'connectionsByIndustry': connectionsByIndustry,
      'connectionsByCompany': connectionsByCompany,
      'topNetworkers': topNetworkers,
    };
  }

  factory NetworkingMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkingMetrics(
      totalConnections: json['totalConnections'] as int,
      newConnections: json['newConnections'] as int,
      totalMessages: json['totalMessages'] as int,
      activeConversations: json['activeConversations'] as int,
      averageConnectionsPerUser: (json['averageConnectionsPerUser'] as num).toDouble(),
      averageMessagesPerUser: (json['averageMessagesPerUser'] as num).toDouble(),
      totalProfileViews: json['totalProfileViews'] as int,
      connectionsByIndustry: Map<String, int>.from(json['connectionsByIndustry']),
      connectionsByCompany: Map<String, int>.from(json['connectionsByCompany']),
      topNetworkers: List<String>.from(json['topNetworkers']),
    );
  }
}

class SessionMetrics {
  final int totalSessions;
  final int totalAttendees;
  final double averageAttendanceRate;
  final int totalCheckIns;
  final double averageRating;
  final Map<String, int> attendanceBySession;
  final Map<String, double> ratingsBySession;
  final List<String> topRatedSessions;
  final List<String> mostAttendedSessions;

  SessionMetrics({
    required this.totalSessions,
    required this.totalAttendees,
    required this.averageAttendanceRate,
    required this.totalCheckIns,
    required this.averageRating,
    required this.attendanceBySession,
    required this.ratingsBySession,
    required this.topRatedSessions,
    required this.mostAttendedSessions,
  });

  double get checkInRate => totalAttendees > 0 ? (totalCheckIns / totalAttendees) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalAttendees': totalAttendees,
      'averageAttendanceRate': averageAttendanceRate,
      'totalCheckIns': totalCheckIns,
      'averageRating': averageRating,
      'attendanceBySession': attendanceBySession,
      'ratingsBySession': ratingsBySession,
      'topRatedSessions': topRatedSessions,
      'mostAttendedSessions': mostAttendedSessions,
    };
  }

  factory SessionMetrics.fromJson(Map<String, dynamic> json) {
    return SessionMetrics(
      totalSessions: json['totalSessions'] as int,
      totalAttendees: json['totalAttendees'] as int,
      averageAttendanceRate: (json['averageAttendanceRate'] as num).toDouble(),
      totalCheckIns: json['totalCheckIns'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      attendanceBySession: Map<String, int>.from(json['attendanceBySession']),
      ratingsBySession: Map<String, double>.from(json['ratingsBySession']),
      topRatedSessions: List<String>.from(json['topRatedSessions']),
      mostAttendedSessions: List<String>.from(json['mostAttendedSessions']),
    );
  }
}

class EventAnalytics {
  final String eventId;
  final DateTime generatedAt;
  final EngagementMetrics engagement;
  final NetworkingMetrics networking;
  final SessionMetrics sessions;
  final Map<String, dynamic> customMetrics;
  final List<AnalyticsMetric> keyMetrics;

  EventAnalytics({
    required this.eventId,
    required this.generatedAt,
    required this.engagement,
    required this.networking,
    required this.sessions,
    required this.customMetrics,
    required this.keyMetrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'generatedAt': generatedAt.toIso8601String(),
      'engagement': engagement.toJson(),
      'networking': networking.toJson(),
      'sessions': sessions.toJson(),
      'customMetrics': customMetrics,
      'keyMetrics': keyMetrics.map((m) => m.toJson()).toList(),
    };
  }

  factory EventAnalytics.fromJson(Map<String, dynamic> json) {
    return EventAnalytics(
      eventId: json['eventId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      engagement: EngagementMetrics.fromJson(json['engagement']),
      networking: NetworkingMetrics.fromJson(json['networking']),
      sessions: SessionMetrics.fromJson(json['sessions']),
      customMetrics: Map<String, dynamic>.from(json['customMetrics']),
      keyMetrics: (json['keyMetrics'] as List)
          .map((m) => AnalyticsMetric.fromJson(m))
          .toList(),
    );
  }
}

class DashboardWidget {
  final String id;
  final String title;
  final MetricType type;
  final String query;
  final Map<String, dynamic> configuration;
  final int position;
  final int width;
  final int height;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.type,
    required this.query,
    required this.configuration,
    required this.position,
    this.width = 1,
    this.height = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'query': query,
      'configuration': configuration,
      'position': position,
      'width': width,
      'height': height,
    };
  }

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] as String,
      title: json['title'] as String,
      type: MetricType.values.firstWhere((e) => e.name == json['type']),
      query: json['query'] as String,
      configuration: Map<String, dynamic>.from(json['configuration']),
      position: json['position'] as int,
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
    );
  }
}