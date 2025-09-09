enum MessageType {
  text,
  image,
  file,
  businessCard,
  meetingRequest,
  system,
}

enum MessageStatus {
  sent,
  delivered,
  read,
  failed,
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? recipientId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final String? fileUrl;
  final String? fileName;
  final String? thumbnailUrl;
  final Map<String, dynamic> metadata;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final bool isEdited;
  final DateTime? editedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.recipientId,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.fileUrl,
    this.fileName,
    this.thumbnailUrl,
    this.metadata = const {},
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.isEdited = false,
    this.editedAt,
  });

  bool get isRead => readAt != null;
  bool get isDelivered => deliveredAt != null;
  bool get hasFile => fileUrl != null;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      recipientId: json['recipientId'],
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status']}',
        orElse: () => MessageStatus.sent,
      ),
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      thumbnailUrl: json['thumbnailUrl'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      sentAt: DateTime.parse(json['sentAt'] ?? DateTime.now().toIso8601String()),
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'recipientId': recipientId,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'thumbnailUrl': thumbnailUrl,
      'metadata': metadata,
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? recipientId,
    String? content,
    MessageType? type,
    MessageStatus? status,
    String? fileUrl,
    String? fileName,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadata: metadata ?? this.metadata,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}