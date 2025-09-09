import '../models/admin_user.dart';
import 'api_service.dart';

class AdminService {
  static AdminUser? _currentAdmin;

  AdminUser? getCurrentAdmin() {
    return _currentAdmin;
  }

  bool get isAuthenticated => _currentAdmin != null;

  Future<AdminUser> signIn(String username, String password) async {
    try {
      final response = await ApiService.post('/auth/admin/login', {
        'username': username,
        'password': password,
      });

      if (response['success'] == true) {
        final adminData = response['admin'];
        final token = response['token'];

        // Store the token
        ApiService.setToken(token);

        _currentAdmin = AdminUser(
          id: adminData['id'],
          username: adminData['username'],
          email: adminData['email'],
          name: adminData['name'],
          role: adminData['role'] == 'owner' ? AdminRole.owner : AdminRole.user,
          permissions: _mapPermissions(adminData['permissions']),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        return _currentAdmin!;
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    ApiService.clearToken();
    _currentAdmin = null;
  }

  // Convert backend permissions to Flutter format
  List<String> _mapPermissions(Map<String, dynamic> permissions) {
    List<String> permissionList = [];
    
    permissions.forEach((key, value) {
      if (value == true) {
        permissionList.add(key);
      }
    });

    return permissionList;
  }

  // User Management
  Future<List<AdminUser>> getAllAdmins() async {
    try {
      final response = await ApiService.get('/admin/admins');
      
      if (response['success'] == true) {
        final List<dynamic> adminList = response['data'];
        
        return adminList.map((adminData) {
          return AdminUser(
            id: adminData['_id'],
            username: adminData['username'],
            email: adminData['email'],
            name: adminData['name'],
            role: adminData['role'] == 'owner' ? AdminRole.owner : AdminRole.user,
            permissions: _mapPermissions(adminData['permissions']),
            createdAt: DateTime.parse(adminData['createdAt']),
            lastLoginAt: adminData['lastLogin'] != null 
                ? DateTime.parse(adminData['lastLogin'])
                : DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch admins');
      }
    } catch (e) {
      throw Exception('Failed to fetch admins: ${e.toString()}');
    }
  }

  Future<AdminUser> createAdmin({
    required String username,
    required String password,
    required String email,
    required String name,
    required AdminRole role,
  }) async {
    try {
      final response = await ApiService.post('/admin/admins', {
        'username': username,
        'password': password,
        'email': email,
        'name': name,
        'role': role == AdminRole.owner ? 'owner' : 'user',
      });

      if (response['success'] == true) {
        final adminData = response['data'];
        
        return AdminUser(
          id: adminData['id'],
          username: adminData['username'],
          email: adminData['email'],
          name: adminData['name'],
          role: adminData['role'] == 'owner' ? AdminRole.owner : AdminRole.user,
          permissions: _mapPermissions(adminData['permissions']),
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to create admin');
      }
    } catch (e) {
      throw Exception('Failed to create admin: ${e.toString()}');
    }
  }

  Future<void> updateAdmin(AdminUser admin) async {
    try {
      final response = await ApiService.put('/admin/admins/${admin.id}', {
        'email': admin.email,
        'name': admin.name,
        'role': admin.role == AdminRole.owner ? 'owner' : 'user',
      });

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to update admin');
      }
    } catch (e) {
      throw Exception('Failed to update admin: ${e.toString()}');
    }
  }

  Future<void> deleteAdmin(String adminId) async {
    try {
      final response = await ApiService.delete('/admin/admins/$adminId');

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete admin');
      }
    } catch (e) {
      throw Exception('Failed to delete admin: ${e.toString()}');
    }
  }

  // Dashboard Statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await ApiService.get('/admin/dashboard/stats');
      
      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch dashboard stats');
      }
    } catch (e) {
      // Return default stats if API fails
      return {
        'totalUsers': 0,
        'totalEvents': 0,
        'activeEvents': 0,
        'totalRegistrations': 0,
        'totalRevenue': 0.0,
        'monthlyRevenue': 0.0,
        'completedEvents': 0,
        'draftEvents': 0,
      };
    }
  }

  // System Health Check
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await ApiService.get('/admin/dashboard/system-health');
      
      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch system health');
      }
    } catch (e) {
      // Return default health data if API fails
      return {
        'database': {'status': 'unknown', 'usage': 'N/A'},
        'storage': {'status': 'unknown', 'usage': 'N/A'},
        'memory': {'status': 'unknown', 'usage': 'N/A'},
        'cpu': {'status': 'unknown', 'usage': 'N/A'},
      };
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalyticsOverview() async {
    try {
      final response = await ApiService.get('/admin/analytics/overview');
      
      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch analytics');
      }
    } catch (e) {
      // Return default analytics if API fails
      return {
        'userGrowth': [],
        'eventCategories': [],
        'topPerformers': [],
      };
    }
  }

  // User Management APIs
  Future<Map<String, dynamic>> getAllUsers({int page = 1, int limit = 10}) async {
    try {
      final response = await ApiService.get('/admin/users?page=$page&limit=$limit');
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getAllEvents({int page = 1, int limit = 10}) async {
    try {
      final response = await ApiService.get('/admin/events?page=$page&limit=$limit');
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch events');
      }
    } catch (e) {
      throw Exception('Failed to fetch events: ${e.toString()}');
    }
  }
}