import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Use 10.0.2.2 for Android Emulator connecting to local server.
  // Use localhost for iOS simulator or web.
  // Use your computer's IP address (e.g., 192.168.x.x) for physical device.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/auth';
    }
    // Note: If you ever test on Windows Desktop app, use localhost too.
    // Platform.isAndroid check would require dart:io which isn't web-compatible without universal_io
    return 'http://10.0.2.2:5000/api/auth';
  }

  /// Register a normal user
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': 'user',
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Register a service provider
  static Future<Map<String, dynamic>> registerServiceProvider({
    required String name,
    required String serviceType,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'service_type': serviceType,
          'email': email,
          'password': password,
          'phone_number': phone,
          'role': 'service_provider',
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = _handleResponse(response);

      if (result['success'] == true) {
        // Save token & role to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', result['data']['token']);
        await prefs.setString('user_role', result['data']['user']['role']);
        await prefs.setInt('user_id', result['data']['user']['id']);
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get current user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {
        'success': true,
        'data': jsonDecode(response.body),
      };
    } else {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return {
        'success': false,
        'message': body['message'] ?? 'Unknown error occurred',
      };
    }
  }
}
