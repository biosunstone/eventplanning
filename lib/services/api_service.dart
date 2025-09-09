import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For Android emulator: use 10.0.2.2 to access host localhost
  // For physical device: replace with your computer's actual IP address
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  static String? _token;

  // Set authentication token
  static void setToken(String token) {
    _token = token;
  }

  // Clear authentication token
  static void clearToken() {
    _token = null;
  }

  // Get headers with authentication
  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Handle API response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['message'] ?? 'Unknown error occurred',
        response.statusCode,
      );
    }
  }

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // PUT request
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  // Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}