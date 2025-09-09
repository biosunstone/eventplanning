enum PhotoCategory {
  keynote,
  session,
  networking,
  meals,
  venue,
  speakers,
  attendees,
  exhibits,
  social,
  behind_scenes,
}

enum PhotoVisibility {
  public,
  attendeesOnly,
  private,
}

class PhotoGalleryItem {
  final String id;
  final String eventId;
  final String uploaderId;
  final String uploaderName;
  final String? uploaderAvatar;
  final String imageUrl;
  final String? thumbnailUrl;
  final String caption;
  final PhotoCategory category;
  final PhotoVisibility visibility;
  final List<String> tags;
  final List<String> taggedPeople;
  final List<String> likedBy;
  final String? sessionId;
  final String? location;
  final DateTime capturedAt;
  final DateTime uploadedAt;
  final Map<String, dynamic> metadata;
  final bool isHighlighted;
  final bool isApproved;
  final int downloadCount;

  PhotoGalleryItem({
    required this.id,
    required this.eventId,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderAvatar,
    required this.imageUrl,
    this.thumbnailUrl,
    this.caption = '',
    required this.category,
    this.visibility = PhotoVisibility.public,
    this.tags = const [],
    this.taggedPeople = const [],
    this.likedBy = const [],
    this.sessionId,
    this.location,
    required this.capturedAt,
    required this.uploadedAt,
    this.metadata = const {},
    this.isHighlighted = false,
    this.isApproved = true,
    this.downloadCount = 0,
  });

  int get likesCount => likedBy.length;
  bool isLikedBy(String userId) => likedBy.contains(userId);
  bool get hasTaggedPeople => taggedPeople.isNotEmpty;

  PhotoGalleryItem copyWith({
    String? id,
    String? eventId,
    String? uploaderId,
    String? uploaderName,
    String? uploaderAvatar,
    String? imageUrl,
    String? thumbnailUrl,
    String? caption,
    PhotoCategory? category,
    PhotoVisibility? visibility,
    List<String>? tags,
    List<String>? taggedPeople,
    List<String>? likedBy,
    String? sessionId,
    String? location,
    DateTime? capturedAt,
    DateTime? uploadedAt,
    Map<String, dynamic>? metadata,
    bool? isHighlighted,
    bool? isApproved,
    int? downloadCount,
  }) {
    return PhotoGalleryItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      uploaderAvatar: uploaderAvatar ?? this.uploaderAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      category: category ?? this.category,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      taggedPeople: taggedPeople ?? this.taggedPeople,
      likedBy: likedBy ?? this.likedBy,
      sessionId: sessionId ?? this.sessionId,
      location: location ?? this.location,
      capturedAt: capturedAt ?? this.capturedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      metadata: metadata ?? this.metadata,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isApproved: isApproved ?? this.isApproved,
      downloadCount: downloadCount ?? this.downloadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'uploaderAvatar': uploaderAvatar,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'category': category.name,
      'visibility': visibility.name,
      'tags': tags.join(','),
      'taggedPeople': taggedPeople.join(','),
      'likedBy': likedBy.join(','),
      'sessionId': sessionId,
      'location': location,
      'capturedAt': capturedAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'metadata': metadata.toString(),
      'isHighlighted': isHighlighted ? 1 : 0,
      'isApproved': isApproved ? 1 : 0,
      'downloadCount': downloadCount,
    };
  }

  factory PhotoGalleryItem.fromJson(Map<String, dynamic> json) {
    return PhotoGalleryItem(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      uploaderId: json['uploaderId'] as String,
      uploaderName: json['uploaderName'] as String,
      uploaderAvatar: json['uploaderAvatar'] as String?,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caption: json['caption'] as String? ?? '',
      category: PhotoCategory.values.firstWhere((e) => e.name == json['category']),
      visibility: PhotoVisibility.values.firstWhere((e) => e.name == json['visibility']),
      tags: (json['tags'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      taggedPeople: (json['taggedPeople'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      likedBy: (json['likedBy'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      sessionId: json['sessionId'] as String?,
      location: json['location'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
      isHighlighted: (json['isHighlighted'] as int? ?? 0) == 1,
      isApproved: (json['isApproved'] as int? ?? 1) == 1,
      downloadCount: json['downloadCount'] as int? ?? 0,
    );
  }
}

class PhotoAlbum {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final String coverImageUrl;
  final String createdBy;
  final List<String> photoIds;
  final PhotoVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAutoGenerated;
  final PhotoCategory? category;

  PhotoAlbum({
    required this.id,
    required this.eventId,
    required this.name,
    this.description = '',
    required this.coverImageUrl,
    required this.createdBy,
    this.photoIds = const [],
    this.visibility = PhotoVisibility.public,
    required this.createdAt,
    required this.updatedAt,
    this.isAutoGenerated = false,
    this.category,
  });

  int get photoCount => photoIds.length;

  PhotoAlbum copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    String? coverImageUrl,
    String? createdBy,
    List<String>? photoIds,
    PhotoVisibility? visibility,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAutoGenerated,
    PhotoCategory? category,
  }) {
    return PhotoAlbum(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdBy: createdBy ?? this.createdBy,
      photoIds: photoIds ?? this.photoIds,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAutoGenerated: isAutoGenerated ?? this.isAutoGenerated,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'createdBy': createdBy,
      'photoIds': photoIds.join(','),
      'visibility': visibility.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isAutoGenerated': isAutoGenerated ? 1 : 0,
      'category': category?.name,
    };
  }

  factory PhotoAlbum.fromJson(Map<String, dynamic> json) {
    return PhotoAlbum(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String,
      createdBy: json['createdBy'] as String,
      photoIds: (json['photoIds'] as String? ?? '').split(',').where((s) => s.isNotEmpty).toList(),
      visibility: PhotoVisibility.values.firstWhere((e) => e.name == json['visibility']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isAutoGenerated: (json['isAutoGenerated'] as int? ?? 0) == 1,
      category: json['category'] != null ? PhotoCategory.values.firstWhere((e) => e.name == json['category']) : null,
    );
  }
}