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

  // Submit Vet/Store Verification
  static Future<Map<String, dynamic>> submitVerification({
    required int userId,
    required String ownerName,
    String? serviceType,
    String? nidFrontUrl,
    String? nidBackUrl,
    String? tinUrl,
    String? tradeUrl,
    String? bvcUrl,
    String? otherUrl,
  }) async {
    try {
      if (serviceType == 'Marketplace Owner') {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores/verify')}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'ownerName': ownerName,
            'nidNumber': nidFrontUrl,
            'tradeLicense': tradeUrl,
          }),
        );
        return _handleResponse(response);
      } else {
        final response = await http.post(
          Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vets/verify')}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'ownerName': ownerName,
            'nidFrontUrl': nidFrontUrl,
            'nidBackUrl': nidBackUrl,
            'tinUrl': tinUrl,
            'tradeUrl': tradeUrl,
            'bvcUrl': bvcUrl,
            'otherUrl': otherUrl,
          }),
        );
        return _handleResponse(response);
      }
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

  // Get All Posts
  static Future<Map<String, dynamic>> getAllPosts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts')}'),
        headers: headers,
        body: jsonEncode(postData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> likePost(int postId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/like')}'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unlikePost(int postId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/unlike')}'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addComment(int postId, int userId, String text) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/comments')}'),
        headers: headers,
        body: jsonEncode({'userId': userId, 'text': text}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPostComments(int postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/comments')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Messaging
  static Future<Map<String, dynamic>> getConversations(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/messages/conversations/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMessages(int conversationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/messages/$conversationId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendMessage(int senderId, int receiverId, String text) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/messages')}'),
        headers: headers,
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'text': text,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Marketplace - Stores
  static Future<Map<String, dynamic>> getAllStores() async {
    try {
      final response = await http.get(Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores')}'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStoreByUserId(int userId) async {
    try {
      final response = await http.get(Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores/$userId')}'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createStore(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores')}'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateStore(int storeId, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores/$storeId')}'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Marketplace - Products
  static Future<Map<String, dynamic>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/products')}'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStoreProducts(int storeId) async {
    try {
      final response = await http.get(Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores/$storeId/products')}'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/products')}'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/products/$productId')}'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Marketplace - Orders
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/orders')}'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStoreOrders(int storeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/orders/store/$storeId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/orders/$orderId/status')}'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadImage(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/upload')}'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': jsonDecode(responseData),
        };
      } else {
        String errMsg = 'Failed to upload image';
        try {
          final decoded = jsonDecode(responseData);
          if (decoded['message'] != null) errMsg = decoded['message'];
        } catch (_) {
          errMsg = responseData; // fallback to raw string (like a 500 HTML page)
        }
        return {
          'success': false,
          'message': 'Status ${response.statusCode}: $errMsg',
        };
      }
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
