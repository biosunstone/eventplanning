import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();
  AdminUser? _currentAdmin;
  bool _isLoading = false;
  String? _error;

  AdminUser? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentAdmin != null;
  bool get isOwnerAdmin => _currentAdmin?.role == AdminRole.owner;
  bool get isUserAdmin => _currentAdmin?.role == AdminRole.user;

  AdminProvider() {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    _currentAdmin = _adminService.getCurrentAdmin();
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final admin = await _adminService.signIn(username, password);
      _currentAdmin = admin;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _adminService.signOut();
      _currentAdmin = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}