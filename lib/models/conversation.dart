import 'message.dart';

enum ConversationType {
  oneOnOne,
  group,
  eventChat,
  sessionChat,
}

class Conversation {
  final String id;
  final String? eventId;
  final String? sessionId;
  final String name;
  final String? description;
  final ConversationType type;
  final List<String> participantIds;
  final String? createdBy;
  final Message? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    this.eventId,
    this.sessionId,
    required this.name,
    this.description,
    required this.type,
    required this.participantIds,
    this.createdBy,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isGroup => type == ConversationType.group;
  bool get hasUnreadMessages => unreadCount > 0;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      eventId: json['eventId'],
      sessionId: json['sessionId'],
      name: json['name'] ?? '',
      description: json['description'],
      type: ConversationType.values.firstWhere(
        (e) => e.toString() == 'ConversationType.${json['type']}',
        orElse: () => ConversationType.oneOnOne,
      ),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      createdBy: json['createdBy'],
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'sessionId': sessionId,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'participantIds': participantIds,
      'createdBy': createdBy,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? id,
    String? eventId,
    String? sessionId,
    String? name,
    String? description,
    ConversationType? type,
    List<String>? participantIds,
    String? createdBy,
    Message? lastMessage,
    int? unreadCount,
    bool? isMuted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      createdBy: createdBy ?? this.createdBy,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}