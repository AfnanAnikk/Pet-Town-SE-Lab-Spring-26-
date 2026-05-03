import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Submit Vet Verification
  static Future<Map<String, dynamic>> submitVerification({
    required int userId,
    required String ownerName,
    required String nidNumber,
    required String tinNumber,
    required String tradeLicense,
    required String bvcRegistration,
    String? otherLicense,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vets/verify')}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'ownerName': ownerName,
          'nidNumber': nidNumber,
          'tinNumber': tinNumber,
          'tradeLicense': tradeLicense,
          'bvcRegistration': bvcRegistration,
          'otherLicense': otherLicense,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Create Booking
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/bookings')}'),
        headers: headers,
        body: jsonEncode(bookingData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get User Bookings
  static Future<Map<String, dynamic>> getUserBookings(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/bookings/user/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Vet Bookings
  static Future<Map<String, dynamic>> getVetBookings(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/bookings/vet/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update Booking Status
  static Future<Map<String, dynamic>> updateBookingStatus(int bookingId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/bookings/$bookingId/status')}'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update Vet Profile
  static Future<Map<String, dynamic>> updateVetProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vets/profile')}'),
        headers: headers,
        body: jsonEncode(profileData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get Vet Profile By User ID
  static Future<Map<String, dynamic>> getVetProfile(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vets/user/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get All Vets
  static Future<Map<String, dynamic>> getAllVets({String? location, String? concern, String? species}) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = <String, dynamic>{};
      if (location != null && location.isNotEmpty) queryParams['location'] = location;
      if (concern != null && concern.isNotEmpty) queryParams['concern'] = concern;
      if (species != null && species.isNotEmpty) queryParams['species'] = species;
      
      var uri = Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vets')}');
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
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
