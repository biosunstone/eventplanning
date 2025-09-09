enum EventCategory {
  conference,
  workshop,
  networking,
  seminar,
  social,
  business,
  sports,
  arts,
  education,
  community,
}

enum EventStatus {
  draft,
  active,
  completed,
  cancelled,
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final EventCategory category;
  final EventStatus status;
  final String organizerId;
  final int maxAttendees;
  final int currentAttendees;
  final double price;
  final List<String> tags;
  final bool isPublic;
  final bool isVirtual;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.category,
    this.status = EventStatus.draft,
    required this.organizerId,
    required this.maxAttendees,
    this.currentAttendees = 0,
    this.price = 0.0,
    this.tags = const [],
    this.isPublic = true,
    this.isVirtual = false,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter for checking if event is active
  bool get isActive => status == EventStatus.active && dateTime.isAfter(DateTime.now());

  // Getter for available capacity
  int get capacity => maxAttendees;

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    EventCategory? category,
    EventStatus? status,
    String? organizerId,
    int? maxAttendees,
    int? currentAttendees,
    double? price,
    List<String>? tags,
    bool? isPublic,
    bool? isVirtual,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      category: category ?? this.category,
      status: status ?? this.status,
      organizerId: organizerId ?? this.organizerId,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      currentAttendees: currentAttendees ?? this.currentAttendees,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      isVirtual: isVirtual ?? this.isVirtual,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['dateTime'] ?? DateTime.now().toIso8601String()),
      location: json['location'] is Map 
          ? json['location']['venue'] ?? 'Unknown Location'
          : json['location'] ?? 'Unknown Location',
      category: _categoryFromString(json['category'] ?? 'business'),
      status: _statusFromString(json['status'] ?? 'draft'),
      organizerId: json['organizer'] is Map 
          ? json['organizer']['_id']
          : json['organizer'] ?? 'unknown',
      maxAttendees: json['capacity'] ?? 100,
      currentAttendees: json['attendees'] is List 
          ? (json['attendees'] as List).length
          : 0,
      price: (json['price'] ?? 0).toDouble(),
      tags: json['tags'] is List 
          ? List<String>.from(json['tags'])
          : [],
      isPublic: json['status'] != 'draft',
      isVirtual: json['isVirtual'] ?? false,
      images: json['images'] is List 
          ? List<String>.from(json['images'])
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'category': category.name,
      'status': status.name,
      'organizerId': organizerId,
      'capacity': maxAttendees,
      'currentAttendees': currentAttendees,
      'price': price,
      'tags': tags,
      'isPublic': isPublic,
      'isVirtual': isVirtual,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static EventCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'conference':
        return EventCategory.conference;
      case 'workshop':
        return EventCategory.workshop;
      case 'networking':
        return EventCategory.networking;
      case 'seminar':
        return EventCategory.seminar;
      case 'social':
        return EventCategory.social;
      case 'sports':
        return EventCategory.sports;
      case 'arts':
        return EventCategory.arts;
      case 'education':
        return EventCategory.education;
      case 'community':
        return EventCategory.community;
      default:
        return EventCategory.business;
    }
  }

  static EventStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return EventStatus.active;
      case 'completed':
        return EventStatus.completed;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'draft':
      default:
        return EventStatus.draft;
    }
  }
}