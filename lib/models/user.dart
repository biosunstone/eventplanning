class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    required this.createdAt,
    this.preferences = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImage,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }
}