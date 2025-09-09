enum PostType {
  general,
  rideshare,
  meetup,
  jobPosting,
  lostFound,
  recommendation,
  question,
  announcement,
}

enum PostStatus {
  active,
  resolved,
  archived,
  hidden,
}

class CommunityPost {
  final String id;
  final String eventId;
  final String authorId;
  final String title;
  final String content;
  final PostType type;
  final PostStatus status;
  final List<String> tags;
  final List<String> imageUrls;
  final String? location;
  final DateTime? eventDate;
  final int likesCount;
  final List<String> likedByIds;
  final int commentsCount;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.eventId,
    required this.authorId,
    required this.title,
    required this.content,
    required this.type,
    this.status = PostStatus.active,
    this.tags = const [],
    this.imageUrls = const [],
    this.location,
    this.eventDate,
    this.likesCount = 0,
    this.likedByIds = const [],
    this.commentsCount = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasImages => imageUrls.isNotEmpty;
  bool get isActive => status == PostStatus.active;

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      authorId: json['authorId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${json['type']}',
        orElse: () => PostType.general,
      ),
      status: PostStatus.values.firstWhere(
        (e) => e.toString() == 'PostStatus.${json['status']}',
        orElse: () => PostStatus.active,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      location: json['location'],
      eventDate: json['eventDate'] != null ? DateTime.parse(json['eventDate']) : null,
      likesCount: json['likesCount'] ?? 0,
      likedByIds: List<String>.from(json['likedByIds'] ?? []),
      commentsCount: json['commentsCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'authorId': authorId,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'tags': tags,
      'imageUrls': imageUrls,
      'location': location,
      'eventDate': eventDate?.toIso8601String(),
      'likesCount': likesCount,
      'likedByIds': likedByIds,
      'commentsCount': commentsCount,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CommunityPost copyWith({
    String? id,
    String? eventId,
    String? authorId,
    String? title,
    String? content,
    PostType? type,
    PostStatus? status,
    List<String>? tags,
    List<String>? imageUrls,
    String? location,
    DateTime? eventDate,
    int? likesCount,
    List<String>? likedByIds,
    int? commentsCount,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      likesCount: likesCount ?? this.likesCount,
      likedByIds: likedByIds ?? this.likedByIds,
      commentsCount: commentsCount ?? this.commentsCount,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}