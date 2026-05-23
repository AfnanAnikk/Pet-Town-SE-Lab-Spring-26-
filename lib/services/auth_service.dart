import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Always use the Render cloud backend
  static const String baseUrl = 'https://pet-town-backend.onrender.com/api/auth';

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
        // Save service_type so login routing knows vet vs marketplace owner
        final serviceType = result['data']['user']['service_type'] ?? '';
        await prefs.setString('service_type', serviceType);
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

  /// Get current user profile
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/$userId'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile(int userId, String displayName, {String? profilePictureUrl}) async {
    try {
      final body = <String, dynamic>{'displayName': displayName};
      if (profilePictureUrl != null) {
        body['profilePictureUrl'] = profilePictureUrl;
      }
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
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
