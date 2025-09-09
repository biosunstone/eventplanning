enum AnnouncementType {
  general,
  urgent,
  schedule_change,
  weather,
  emergency,
  networking,
  meal,
  transport,
  technical,
  social,
}

enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent,
  critical,
}

enum AnnouncementStatus {
  draft,
  scheduled,
  active,
  expired,
  cancelled,
}

class Announcement {
  final String id;
  final String eventId;
  final String title;
  final String content;
  final AnnouncementType type;
  final AnnouncementPriority priority;
  final AnnouncementStatus status;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? expiresAt;
  final List<String> targetAudience;
  final List<String> tags;
  final String? actionButtonText;
  final String? actionButtonUrl;
  final String? imageUrl;
  final bool isPinned;
  final bool sendPushNotification;
  final bool sendEmail;
  final bool sendSMS;
  final List<String> readByUsers;
  final List<String> dismissedByUsers;
  final Map<String, dynamic> customFields;
  final int viewCount;
  final int clickCount;

  Announcement({
    required this.id,
    required this.eventId,
    required this.title,
    required this.content,
    required this.type,
    this.priority = AnnouncementPriority.normal,
    this.status = AnnouncementStatus.draft,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    this.scheduledAt,
    this.expiresAt,
    this.targetAudience = const [],
    this.tags = const [],
    this.actionButtonText,
    this.actionButtonUrl,
    this.imageUrl,
    this.isPinned = false,
    this.sendPushNotification = true,
    this.sendEmail = false,
    this.sendSMS = false,
    this.readByUsers = const [],
    this.dismissedByUsers = const [],
    this.customFields = const {},
    this.viewCount = 0,
    this.clickCount = 0,
  });

  bool get isActive => status == AnnouncementStatus.active;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isScheduled => scheduledAt != null && DateTime.now().isBefore(scheduledAt!);
  bool get shouldShow => isActive && !isExpired;
  int get readCount => readByUsers.length;
  int get dismissedCount => dismissedByUsers.length;
  
  bool isReadBy(String userId) => readByUsers.contains(userId);
  bool isDismissedBy(String userId) => dismissedByUsers.contains(userId);

  Announcement copyWith({
    String? id,
    String? eventId,
    String? title,
    String? content,
    AnnouncementType? type,
    AnnouncementPriority? priority,
    AnnouncementStatus? status,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    List<String>? targetAudience,
    List<String>? tags,
    String? actionButtonText,
    String? actionButtonUrl,
    String? imageUrl,
    bool? isPinned,
    bool? sendPushNotification,
    bool? sendEmail,
    bool? sendSMS,
    List<String>? readByUsers,
    List<String>? dismissedByUsers,
    Map<String, dynamic>? customFields,
    int? viewCount,
    int? clickCount,
  }) {
    return Announcement(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      expiresAt: expiresAt ?? this.expiresAt,
      targetAudience: targetAudience ?? this.targetAudience,
      tags: tags ?? this.tags,
      actionButtonText: actionButtonText ?? this.actionButtonText,
      actionButtonUrl: actionButtonUrl ?? this.actionButtonUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isPinned: isPinned ?? this.isPinned,
      sendPushNotification: sendPushNotification ?? this.sendPushNotification,
      sendEmail: sendEmail ?? this.sendEmail,
      sendSMS: sendSMS ?? this.sendSMS,
      readByUsers: readByUsers ?? this.readByUsers,
      dismissedByUsers: dismissedByUsers ?? this.dismissedByUsers,
      customFields: customFields ?? this.customFields,
      viewCount: viewCount ?? this.viewCount,
      clickCount: clickCount ?? this.clickCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'content': content,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'createdAt': createdAt.toIso8601String(),
      'scheduledAt': scheduledAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'targetAudience': targetAudience.join(','),
      'tags': tags.join(','),
      'actionButtonText': actionButtonText,
      'actionButtonUrl': actionButtonUrl,
      'imageUrl': imageUrl,
      'isPinned': isPinned ? 1 : 0,
      'sendPushNotification': sendPushNotification ? 1 : 0,
      'sendEmail': sendEmail ? 1 : 0,
      'sendSMS': sendSMS ? 1 : 0,
      'readByUsers': readByUsers.join(','),
      'dismissedByUsers': dismissedByUsers.join(','),
      'customFields': customFields.toString(),
      'viewCount': viewCount,
      'clickCount': clickCount,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: AnnouncementType.values.firstWhere((e) => e.name == json['type']),
      priority: AnnouncementPriority.values.firstWhere((e) => e.name == json['priority']),
      status: AnnouncementStatus.values.firstWhere((e) => e.name == json['status']),
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt'] as String) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      targetAudience: (json['targetAudience'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      tags: (json['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      actionButtonText: json['actionButtonText'] as String?,
      actionButtonUrl: json['actionButtonUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isPinned: (json['isPinned'] as int? ?? 0) == 1,
      sendPushNotification: (json['sendPushNotification'] as int? ?? 1) == 1,
      sendEmail: (json['sendEmail'] as int? ?? 0) == 1,
      sendSMS: (json['sendSMS'] as int? ?? 0) == 1,
      readByUsers: (json['readByUsers'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      dismissedByUsers: (json['dismissedByUsers'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      customFields: json['customFields'] != null ? Map<String, dynamic>.from(json['customFields']) : {},
      viewCount: json['viewCount'] as int? ?? 0,
      clickCount: json['clickCount'] as int? ?? 0,
    );
  }
}

class AnnouncementTemplate {
  final String id;
  final String name;
  final String title;
  final String content;
  final AnnouncementType type;
  final AnnouncementPriority priority;
  final String? actionButtonText;
  final List<String> tags;
  final bool isDefault;
  final DateTime createdAt;

  AnnouncementTemplate({
    required this.id,
    required this.name,
    required this.title,
    required this.content,
    required this.type,
    this.priority = AnnouncementPriority.normal,
    this.actionButtonText,
    this.tags = const [],
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'content': content,
      'type': type.name,
      'priority': priority.name,
      'actionButtonText': actionButtonText,
      'tags': tags.join(','),
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AnnouncementTemplate.fromJson(Map<String, dynamic> json) {
    return AnnouncementTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: AnnouncementType.values.firstWhere((e) => e.name == json['type']),
      priority: AnnouncementPriority.values.firstWhere((e) => e.name == json['priority']),
      actionButtonText: json['actionButtonText'] as String?,
      tags: (json['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      isDefault: (json['isDefault'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Announcement toAnnouncement({
    required String eventId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  }) {
    return Announcement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      eventId: eventId,
      title: title,
      content: content,
      type: type,
      priority: priority,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      expiresAt: expiresAt,
      tags: tags,
      actionButtonText: actionButtonText,
    );
  }
}