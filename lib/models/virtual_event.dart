enum StreamStatus {
  scheduled,
  live,
  ended,
  cancelled,
  technical_difficulties,
}

enum StreamQuality {
  auto,
  low,
  medium,
  high,
  ultra,
}

enum StreamType {
  keynote,
  breakout,
  workshop,
  panel,
  networking,
  entertainment,
  exhibition,
  qa_session,
}

enum InteractionType {
  chat,
  poll,
  qa,
  reaction,
  breakout_room,
  screen_share,
  whiteboard,
}

enum ViewerRole {
  attendee,
  speaker,
  moderator,
  organizer,
  admin,
}

class VirtualSession {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final StreamType type;
  final StreamStatus status;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String streamUrl;
  final String? recordingUrl;
  final List<String> speakerIds;
  final List<String> moderatorIds;
  final int maxAttendees;
  final List<String> attendeeIds;
  final List<String> enabledInteractions;
  final Map<String, dynamic> streamSettings;
  final Map<String, dynamic> metadata;
  final String thumbnailUrl;
  final List<String> tags;
  final bool isRecorded;
  final bool allowReplay;

  VirtualSession({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    required this.streamUrl,
    this.recordingUrl,
    this.speakerIds = const [],
    this.moderatorIds = const [],
    this.maxAttendees = 1000,
    this.attendeeIds = const [],
    this.enabledInteractions = const [],
    this.streamSettings = const {},
    this.metadata = const {},
    required this.thumbnailUrl,
    this.tags = const [],
    this.isRecorded = true,
    this.allowReplay = true,
  });

  bool get isLive => status == StreamStatus.live;
  bool get isScheduled => status == StreamStatus.scheduled;
  bool get hasEnded => status == StreamStatus.ended;
  bool get isUpcoming => DateTime.now().isBefore(scheduledStart);
  bool get isHappening => DateTime.now().isAfter(scheduledStart) && DateTime.now().isBefore(scheduledEnd);
  Duration get duration => scheduledEnd.difference(scheduledStart);
  int get currentViewers => attendeeIds.length;

  VirtualSession copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    StreamType? type,
    StreamStatus? status,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? actualStart,
    DateTime? actualEnd,
    String? streamUrl,
    String? recordingUrl,
    List<String>? speakerIds,
    List<String>? moderatorIds,
    int? maxAttendees,
    List<String>? attendeeIds,
    List<String>? enabledInteractions,
    Map<String, dynamic>? streamSettings,
    Map<String, dynamic>? metadata,
    String? thumbnailUrl,
    List<String>? tags,
    bool? isRecorded,
    bool? allowReplay,
  }) {
    return VirtualSession(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      actualStart: actualStart ?? this.actualStart,
      actualEnd: actualEnd ?? this.actualEnd,
      streamUrl: streamUrl ?? this.streamUrl,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      speakerIds: speakerIds ?? this.speakerIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      enabledInteractions: enabledInteractions ?? this.enabledInteractions,
      streamSettings: streamSettings ?? this.streamSettings,
      metadata: metadata ?? this.metadata,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      isRecorded: isRecorded ?? this.isRecorded,
      allowReplay: allowReplay ?? this.allowReplay,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      'actualStart': actualStart?.toIso8601String(),
      'actualEnd': actualEnd?.toIso8601String(),
      'streamUrl': streamUrl,
      'recordingUrl': recordingUrl,
      'speakerIds': speakerIds.join(','),
      'moderatorIds': moderatorIds.join(','),
      'maxAttendees': maxAttendees,
      'attendeeIds': attendeeIds.join(','),
      'enabledInteractions': enabledInteractions.join(','),
      'streamSettings': streamSettings.toString(),
      'metadata': metadata.toString(),
      'thumbnailUrl': thumbnailUrl,
      'tags': tags.join(','),
      'isRecorded': isRecorded,
      'allowReplay': allowReplay,
    };
  }

  factory VirtualSession.fromJson(Map<String, dynamic> json) {
    return VirtualSession(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: StreamType.values.firstWhere((e) => e.name == json['type']),
      status: StreamStatus.values.firstWhere((e) => e.name == json['status']),
      scheduledStart: DateTime.parse(json['scheduledStart']),
      scheduledEnd: DateTime.parse(json['scheduledEnd']),
      actualStart: json['actualStart'] != null ? DateTime.parse(json['actualStart']) : null,
      actualEnd: json['actualEnd'] != null ? DateTime.parse(json['actualEnd']) : null,
      streamUrl: json['streamUrl'] as String,
      recordingUrl: json['recordingUrl'] as String?,
      speakerIds: json['speakerIds'] != null 
          ? (json['speakerIds'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      moderatorIds: json['moderatorIds'] != null
          ? (json['moderatorIds'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      maxAttendees: json['maxAttendees'] as int? ?? 1000,
      attendeeIds: json['attendeeIds'] != null
          ? (json['attendeeIds'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      enabledInteractions: json['enabledInteractions'] != null
          ? (json['enabledInteractions'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      streamSettings: Map<String, dynamic>.from(json['streamSettings'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      thumbnailUrl: json['thumbnailUrl'] as String,
      tags: json['tags'] != null
          ? (json['tags'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      isRecorded: json['isRecorded'] as bool? ?? true,
      allowReplay: json['allowReplay'] as bool? ?? true,
    );
  }
}

class StreamMessage {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final InteractionType type;
  final Map<String, dynamic> metadata;
  final bool isFromModerator;
  final bool isPinned;
  final String? replyToId;
  final List<String> reactions;

  StreamMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    required this.type,
    this.metadata = const {},
    this.isFromModerator = false,
    this.isPinned = false,
    this.replyToId,
    this.reactions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'metadata': metadata.toString(),
      'isFromModerator': isFromModerator,
      'isPinned': isPinned,
      'replyToId': replyToId,
      'reactions': reactions.join(','),
    };
  }

  factory StreamMessage.fromJson(Map<String, dynamic> json) {
    return StreamMessage(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp']),
      type: InteractionType.values.firstWhere((e) => e.name == json['type']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isFromModerator: json['isFromModerator'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      replyToId: json['replyToId'] as String?,
      reactions: json['reactions'] != null
          ? (json['reactions'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
    );
  }
}

class BreakoutRoom {
  final String id;
  final String sessionId;
  final String name;
  final String description;
  final int maxParticipants;
  final List<String> participantIds;
  final List<String> moderatorIds;
  final DateTime createdAt;
  final bool isActive;
  final Map<String, dynamic> settings;

  BreakoutRoom({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.description,
    this.maxParticipants = 10,
    this.participantIds = const [],
    this.moderatorIds = const [],
    required this.createdAt,
    this.isActive = true,
    this.settings = const {},
  });

  bool get isFull => participantIds.length >= maxParticipants;
  int get currentParticipants => participantIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'name': name,
      'description': description,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds.join(','),
      'moderatorIds': moderatorIds.join(','),
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'settings': settings.toString(),
    };
  }

  factory BreakoutRoom.fromJson(Map<String, dynamic> json) {
    return BreakoutRoom(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      maxParticipants: json['maxParticipants'] as int? ?? 10,
      participantIds: json['participantIds'] != null
          ? (json['participantIds'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      moderatorIds: json['moderatorIds'] != null
          ? (json['moderatorIds'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] as bool? ?? true,
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }
}

class StreamReaction {
  final String id;
  final String sessionId;
  final String userId;
  final String reaction;
  final DateTime timestamp;
  final double? x; // Screen position for floating reactions
  final double? y;

  StreamReaction({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.reaction,
    required this.timestamp,
    this.x,
    this.y,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'reaction': reaction,
      'timestamp': timestamp.toIso8601String(),
      'x': x,
      'y': y,
    };
  }

  factory StreamReaction.fromJson(Map<String, dynamic> json) {
    return StreamReaction(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      reaction: json['reaction'] as String,
      timestamp: DateTime.parse(json['timestamp']),
      x: json['x'] as double?,
      y: json['y'] as double?,
    );
  }
}

class VirtualEventSettings {
  final String eventId;
  final bool enableChat;
  final bool enableReactions;
  final bool enablePolls;
  final bool enableQA;
  final bool enableBreakoutRooms;
  final bool enableScreenShare;
  final bool enableRecording;
  final bool moderateChatMessages;
  final int maxChatMessageLength;
  final List<String> bannedWords;
  final Map<String, dynamic> streamQualitySettings;
  final Map<String, dynamic> networkingSettings;
  final List<String> customReactions;

  VirtualEventSettings({
    required this.eventId,
    this.enableChat = true,
    this.enableReactions = true,
    this.enablePolls = true,
    this.enableQA = true,
    this.enableBreakoutRooms = true,
    this.enableScreenShare = false,
    this.enableRecording = true,
    this.moderateChatMessages = true,
    this.maxChatMessageLength = 500,
    this.bannedWords = const [],
    this.streamQualitySettings = const {},
    this.networkingSettings = const {},
    this.customReactions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'enableChat': enableChat,
      'enableReactions': enableReactions,
      'enablePolls': enablePolls,
      'enableQA': enableQA,
      'enableBreakoutRooms': enableBreakoutRooms,
      'enableScreenShare': enableScreenShare,
      'enableRecording': enableRecording,
      'moderateChatMessages': moderateChatMessages,
      'maxChatMessageLength': maxChatMessageLength,
      'bannedWords': bannedWords.join(','),
      'streamQualitySettings': streamQualitySettings.toString(),
      'networkingSettings': networkingSettings.toString(),
      'customReactions': customReactions.join(','),
    };
  }

  factory VirtualEventSettings.fromJson(Map<String, dynamic> json) {
    return VirtualEventSettings(
      eventId: json['eventId'] as String,
      enableChat: json['enableChat'] as bool? ?? true,
      enableReactions: json['enableReactions'] as bool? ?? true,
      enablePolls: json['enablePolls'] as bool? ?? true,
      enableQA: json['enableQA'] as bool? ?? true,
      enableBreakoutRooms: json['enableBreakoutRooms'] as bool? ?? true,
      enableScreenShare: json['enableScreenShare'] as bool? ?? false,
      enableRecording: json['enableRecording'] as bool? ?? true,
      moderateChatMessages: json['moderateChatMessages'] as bool? ?? true,
      maxChatMessageLength: json['maxChatMessageLength'] as int? ?? 500,
      bannedWords: json['bannedWords'] != null
          ? (json['bannedWords'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      streamQualitySettings: Map<String, dynamic>.from(json['streamQualitySettings'] ?? {}),
      networkingSettings: Map<String, dynamic>.from(json['networkingSettings'] ?? {}),
      customReactions: json['customReactions'] != null
          ? (json['customReactions'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
    );
  }
}

class ViewerSession {
  final String userId;
  final String sessionId;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final Duration watchTime;
  final ViewerRole role;
  final StreamQuality quality;
  final Map<String, dynamic> metrics;
  final List<String> interactions;

  ViewerSession({
    required this.userId,
    required this.sessionId,
    required this.joinedAt,
    this.leftAt,
    required this.watchTime,
    required this.role,
    required this.quality,
    this.metrics = const {},
    this.interactions = const [],
  });

  bool get isCurrentlyWatching => leftAt == null;
  Duration get sessionDuration => (leftAt ?? DateTime.now()).difference(joinedAt);

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'watchTime': watchTime.inSeconds,
      'role': role.name,
      'quality': quality.name,
      'metrics': metrics.toString(),
      'interactions': interactions.join(','),
    };
  }

  factory ViewerSession.fromJson(Map<String, dynamic> json) {
    return ViewerSession(
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      joinedAt: DateTime.parse(json['joinedAt']),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
      watchTime: Duration(seconds: json['watchTime'] as int? ?? 0),
      role: ViewerRole.values.firstWhere((e) => e.name == json['role']),
      quality: StreamQuality.values.firstWhere((e) => e.name == json['quality']),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      interactions: json['interactions'] != null
          ? (json['interactions'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
    );
  }
}