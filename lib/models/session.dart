enum SessionType {
  keynote,
  presentation,
  workshop,
  panel,
  breakout,
  networking,
  meal,
  break_,
  other,
}

enum SessionFormat {
  inPerson,
  virtual,
  hybrid,
}

class Session {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final SessionType type;
  final SessionFormat format;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? room;
  final String? virtualLink;
  final int maxAttendees;
  final List<String> speakerIds;
  final List<String> attendeeIds;
  final List<String> tags;
  final bool requiresRegistration;
  final bool isRecorded;
  final String? recordingUrl;
  final String? materialsUrl;
  final Map<String, dynamic> customFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  Session({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.type,
    this.format = SessionFormat.inPerson,
    required this.startTime,
    required this.endTime,
    this.location,
    this.room,
    this.virtualLink,
    this.maxAttendees = 0,
    this.speakerIds = const [],
    this.attendeeIds = const [],
    this.tags = const [],
    this.requiresRegistration = false,
    this.isRecorded = false,
    this.recordingUrl,
    this.materialsUrl,
    this.customFields = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration => endTime.difference(startTime);
  bool get isVirtual => format == SessionFormat.virtual || format == SessionFormat.hybrid;
  bool get isFull => maxAttendees > 0 && attendeeIds.length >= maxAttendees;
  int get availableSpots => maxAttendees > 0 ? maxAttendees - attendeeIds.length : -1;

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: SessionType.values.firstWhere(
        (e) => e.toString() == 'SessionType.${json['type']}',
        orElse: () => SessionType.other,
      ),
      format: SessionFormat.values.firstWhere(
        (e) => e.toString() == 'SessionFormat.${json['format']}',
        orElse: () => SessionFormat.inPerson,
      ),
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      location: json['location'],
      room: json['room'],
      virtualLink: json['virtualLink'],
      maxAttendees: json['maxAttendees'] ?? 0,
      speakerIds: List<String>.from(json['speakerIds'] ?? []),
      attendeeIds: List<String>.from(json['attendeeIds'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      requiresRegistration: json['requiresRegistration'] ?? false,
      isRecorded: json['isRecorded'] ?? false,
      recordingUrl: json['recordingUrl'],
      materialsUrl: json['materialsUrl'],
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'format': format.toString().split('.').last,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'room': room,
      'virtualLink': virtualLink,
      'maxAttendees': maxAttendees,
      'speakerIds': speakerIds,
      'attendeeIds': attendeeIds,
      'tags': tags,
      'requiresRegistration': requiresRegistration,
      'isRecorded': isRecorded,
      'recordingUrl': recordingUrl,
      'materialsUrl': materialsUrl,
      'customFields': customFields,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Session copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    SessionType? type,
    SessionFormat? format,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? room,
    String? virtualLink,
    int? maxAttendees,
    List<String>? speakerIds,
    List<String>? attendeeIds,
    List<String>? tags,
    bool? requiresRegistration,
    bool? isRecorded,
    String? recordingUrl,
    String? materialsUrl,
    Map<String, dynamic>? customFields,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      format: format ?? this.format,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      room: room ?? this.room,
      virtualLink: virtualLink ?? this.virtualLink,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      speakerIds: speakerIds ?? this.speakerIds,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      tags: tags ?? this.tags,
      requiresRegistration: requiresRegistration ?? this.requiresRegistration,
      isRecorded: isRecorded ?? this.isRecorded,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      materialsUrl: materialsUrl ?? this.materialsUrl,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}