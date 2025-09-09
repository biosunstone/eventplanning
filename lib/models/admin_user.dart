enum AdminRole {
  owner,
  user,
}

class AdminUser {
  final String id;
  final String username;
  final String email;
  final String name;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;

  AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
  });

  bool get isOwner => role == AdminRole.owner;
  bool get isUserAdmin => role == AdminRole.user;

  String get roleDisplayName {
    switch (role) {
      case AdminRole.owner:
        return 'Owner Admin';
      case AdminRole.user:
        return 'User Admin';
    }
  }

  bool hasPermission(String permission) {
    if (role == AdminRole.owner) return true; // Owner has all permissions
    return permissions.contains(permission);
  }

  AdminUser copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    AdminRole? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return AdminUser(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'role': role.name,
      'permissions': permissions,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      name: json['name'],
      role: AdminRole.values.firstWhere((e) => e.name == json['role']),
      permissions: List<String>.from(json['permissions'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      isActive: json['isActive'] ?? true,
    );
  }
}

// Admin Permissions Constants
class AdminPermissions {
  // User Management
  static const String viewUsers = 'view_users';
  static const String editUsers = 'edit_users';
  static const String deleteUsers = 'delete_users';
  static const String createAdmins = 'create_admins';
  
  // Event Management
  static const String viewEvents = 'view_events';
  static const String createEvents = 'create_events';
  static const String editEvents = 'edit_events';
  static const String deleteEvents = 'delete_events';
  
  // Content Management
  static const String moderateContent = 'moderate_content';
  static const String manageAnnouncements = 'manage_announcements';
  static const String managePhotos = 'manage_photos';
  
  // Analytics
  static const String viewAnalytics = 'view_analytics';
  static const String viewFinancials = 'view_financials';
  static const String exportData = 'export_data';
  
  // System Settings
  static const String systemSettings = 'system_settings';
  static const String backupRestore = 'backup_restore';
  
  static List<String> get ownerPermissions => [
    viewUsers, editUsers, deleteUsers, createAdmins,
    viewEvents, createEvents, editEvents, deleteEvents,
    moderateContent, manageAnnouncements, managePhotos,
    viewAnalytics, viewFinancials, exportData,
    systemSettings, backupRestore,
  ];
  
  static List<String> get userAdminPermissions => [
    viewUsers, editUsers,
    viewEvents, createEvents, editEvents,
    moderateContent, manageAnnouncements, managePhotos,
    viewAnalytics,
  ];
}