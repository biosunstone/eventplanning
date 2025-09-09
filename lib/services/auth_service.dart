import '../models/user.dart';

class AuthService {
  static User? _currentUser;
  static final Map<String, Map<String, String>> _users = {
    'demo@example.com': {
      'password': 'password123',
      'name': 'Demo User',
      'id': 'user1',
    },
    'admin@eventapp.com': {
      'password': 'admin123',
      'name': 'Event Admin',
      'id': 'admin1',
    },
  };

  User? getCurrentUser() {
    return _currentUser;
  }

  bool get isAuthenticated => _currentUser != null;

  Future<User> signInWithEmailAndPassword(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_users.containsKey(email)) {
      throw Exception('No user found with this email address.');
    }

    if (_users[email]!['password'] != password) {
      throw Exception('Invalid password.');
    }

    final userData = _users[email]!;
    _currentUser = User(
      id: userData['id']!,
      email: email,
      name: userData['name']!,
      createdAt: DateTime.now(),
    );

    return _currentUser!;
  }

  Future<User> createUserWithEmailAndPassword(String email, String password, String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_users.containsKey(email)) {
      throw Exception('An account already exists with this email address.');
    }

    if (password.length < 6) {
      throw Exception('Password is too weak. Please choose a stronger password.');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Invalid email address format.');
    }

    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _users[email] = {
      'password': password,
      'name': name,
      'id': userId,
    };

    _currentUser = User(
      id: userId,
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );

    return _currentUser!;
  }

  Future<void> signOut() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  Future<void> resetPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_users.containsKey(email)) {
      throw Exception('No user found with this email address.');
    }

    // In a real app, this would send an email
    // For demo purposes, we just simulate success
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}