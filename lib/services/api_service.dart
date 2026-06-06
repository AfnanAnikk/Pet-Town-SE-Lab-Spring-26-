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
  static Future<Map<String, dynamic>> getAllVets({
    String? location,
    String? concern,
    String? species,
    List<String>? dates,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{};

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }

      if (concern != null && concern.isNotEmpty) {
        queryParams['concern'] = concern;
      }

      if (species != null && species.isNotEmpty) {
        queryParams['species'] = species;
      }

      if (dates != null && dates.isNotEmpty) {
        queryParams['dates'] = dates.join(',');
      }

      var uri = Uri.parse(
        AuthService.baseUrl.replaceAll('/api/auth', '/api/vets'),
      );

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

  static Future<Map<String, dynamic>> createAdoption(Map<String, dynamic> adoptionData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/adoptions')}'),
        headers: headers,
        body: jsonEncode(adoptionData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> requestAdoption(
    int adoptionId,
    Map<String, dynamic> requestData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/adoptions/$adoptionId/request')}'),
        headers: headers,
        body: jsonEncode(requestData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserAdoptionRequests(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/adoptions/requests/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getOwnerAdoptionRequests(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/adoptions/owner-requests/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateAdoptionRequestStatus(
    int requestId,
    String status,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/adoptions/requests/$requestId/status')}'),
        headers: headers,
        body: jsonEncode({'status': status}),
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

  static Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getPostById(int postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> savePost(int postId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/save')}'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unsavePost(int postId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/unsave')}'),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSavedPosts(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/saved/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> isPostSaved(int postId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/saved/$userId/status/$postId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> isPostLiked(int postId, int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/posts/$postId/liked/$userId')}'),
        headers: headers,
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

  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/auth/users')}'),
        headers: headers,
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

  // --- Coupons ---
  static Future<Map<String, dynamic>> getStoreCoupons(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/stores/$storeId/coupons')}'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/coupons')}'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateCoupon(int couponId, Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/coupons/$couponId')}'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteCoupon(int couponId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/coupons/$couponId')}'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> validateCoupon(int storeId, String code, double orderAmount) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/marketplace/coupons/validate')}'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'storeId': storeId,
          'code': code,
          'orderAmount': orderAmount,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Vet Vouchers ---
  static Future<Map<String, dynamic>> getVetVouchers(int vetId) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vouchers/vet/$vetId')}'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAvailableVetVouchers(int vetId) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vouchers/vet/$vetId/available')}'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createVetVoucher(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vouchers')}'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateVetVoucher(int voucherId, Map<String, dynamic> payload) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vouchers/$voucherId')}'),
        headers: await _getHeaders(),
        body: jsonEncode(payload),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteVetVoucher(int voucherId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vouchers/$voucherId')}'),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> validateVetVoucher(int vetId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vouchers/validate')}'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'vetId': vetId,
          'code': code,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ================= SALONS ================= //
  static Future<Map<String, dynamic>> getAllSalons({
    String? location,
    String? concern,
  }) async {
    try {
      final headers = await _getHeaders();
      var queryParams = <String>[];
      if (location != null) queryParams.add('location=$location');
      if (concern != null) queryParams.add('concern=$concern');

      String queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons')}$queryString'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSalonProfile(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/user')}/$userId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateSalonProfile(Map<String, dynamic> profileData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/profile')}'),
        headers: headers,
        body: jsonEncode(profileData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createSalonBooking(Map<String, dynamic> bookingData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/bookings')}'),
        headers: headers,
        body: jsonEncode(bookingData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getProviderSalonBookings(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/bookings/provider')}/$userId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateSalonBookingStatus(String bookingId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/bookings')}/$bookingId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> validateSalonVoucher(String code, String salonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/vouchers/validate')}'),
        headers: headers,
        body: jsonEncode({'code': code, 'salonId': salonId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSalonVouchers(String providerUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/vouchers/provider')}/$providerUserId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createSalonVoucher(String providerUserId, Map<String, dynamic> voucherData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/vouchers/provider')}/$providerUserId'),
        headers: headers,
        body: jsonEncode(voucherData),
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

  // Add Vet Review
  static Future<Map<String, dynamic>> addVetReview(String vetId, String bookingId, double rating, String reviewText) async {
    try {
      final headers = await _getHeaders();
      final userId = await AuthService.getUserId();
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/vets')}/$vetId/reviews'),
        headers: headers,
          body: jsonEncode({
            'userId': userId,
            'bookingId': bookingId,
            'rating': rating,
            'reviewText': reviewText,
          }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add Salon Review
  static Future<Map<String, dynamic>> addSalonReview(String salonId, String bookingId, double rating, String reviewText) async {
    try {
      final headers = await _getHeaders();
      final userId = await AuthService.getUserId();
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons')}/$salonId/reviews'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'bookingId': bookingId,
          'rating': rating,
          'reviewText': reviewText,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get User Salon Bookings
  static Future<Map<String, dynamic>> getUserSalonBookings(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/salons/bookings/user')}/$userId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Social Features
  static Future<Map<String, dynamic>> followUser(int followingId) async {
    try {
      final headers = await _getHeaders();
      final followerId = await AuthService.getUserId();
      if (followerId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/follow')}'),
        headers: headers,
        body: jsonEncode({
          'followerId': followerId,
          'followingId': followingId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> unfollowUser(int followingId) async {
    try {
      final headers = await _getHeaders();
      final followerId = await AuthService.getUserId();
      if (followerId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/unfollow')}'),
        headers: headers,
        body: jsonEncode({
          'followerId': followerId,
          'followingId': followingId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFollowStatus(int followingId) async {
    try {
      final headers = await _getHeaders();
      final followerId = await AuthService.getUserId();
      if (followerId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/follow-status')}?followerId=$followerId&followingId=$followingId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFollowCounts(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/counts/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFollowers(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/followers/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFollowing(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/following/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  

  static Future<Map<String, dynamic>> globalSearch(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/search')}?q=$query'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getNotifications(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/notifications')}?userId=$userId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUnreadNotificationsCount(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/notifications/unread-count')}?userId=$userId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'count': 0};
    }
  }


  // ─────────────────────────────────────────────────────────────────────────
  //  EVENTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetch a paginated, optionally-filtered list of public events.
  static Future<Map<String, dynamic>> getEvents({
    String? status,
    String? category,
    String? petType,
    String? location,
    String? search,
    String? dateFrom,
    String? dateTo,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final headers = await _getHeaders();
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (category != null && category.isNotEmpty) params['category'] = category;
      if (petType != null && petType.isNotEmpty) params['petType'] = petType;
      if (location != null && location.isNotEmpty) params['location'] = location;
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (dateFrom != null && dateFrom.isNotEmpty) params['dateFrom'] = dateFrom;
      if (dateTo != null && dateTo.isNotEmpty) params['dateTo'] = dateTo;

      final uri = Uri.parse(
        AuthService.baseUrl.replaceAll('/api/auth', '/api/events'),
      ).replace(queryParameters: params);

      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch trending events (sorted by participant count / engagement).
  static Future<Map<String, dynamic>> getTrendingEvents() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl.replaceAll('/api/auth', '/api/events/trending'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch events within [radiusKm] kilometres of a geographic point.
  static Future<Map<String, dynamic>> getNearbyEvents(
    double lat,
    double lon, {
    double radiusKm = 25,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        AuthService.baseUrl.replaceAll('/api/auth', '/api/events/nearby'),
      ).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radius': radiusKm.toString(),
      });
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch a single event by its ID.
  static Future<Map<String, dynamic>> getEventById(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl.replaceAll('/api/auth', '/api/events/$eventId'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch all events created by a specific user.
  static Future<Map<String, dynamic>> getEventsByUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl.replaceAll('/api/auth', '/api/events/user/$userId'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create a new event. [eventData] must include at minimum title, description,
  /// category, petType, startDatetime, location, and userId.
  static Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> eventData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl.replaceAll('/api/auth', '/api/events'),
        ),
        headers: headers,
        body: jsonEncode(eventData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update an existing event. Only the organizer may do this.
  static Future<Map<String, dynamic>> updateEvent(
    int eventId,
    Map<String, dynamic> eventData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(
          AuthService.baseUrl.replaceAll('/api/auth', '/api/events/$eventId'),
        ),
        headers: headers,
        body: jsonEncode(eventData),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Delete an event (organizer only).
  static Future<Map<String, dynamic>> deleteEvent(
    int eventId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId'),
        ).replace(queryParameters: {'userId': userId.toString()}),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Change the lifecycle status of an event (organizer only).
  /// [status] is one of: draft | upcoming | ongoing | completed | cancelled
  static Future<Map<String, dynamic>> updateEventStatus(
    int eventId,
    String status,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/status'),
        ),
        headers: headers,
        body: jsonEncode({'status': status, 'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Participation ─────────────────────────────────────────────────────────

  /// Join an event with either 'interested' or 'going' status.
  static Future<Map<String, dynamic>> joinEvent(
    int eventId,
    int userId,
    String participationStatus,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/join'),
        ),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'status': participationStatus,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Leave / cancel participation in an event.
  static Future<Map<String, dynamic>> leaveEvent(
    int eventId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/leave'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Retrieve all participants for an event.
  static Future<Map<String, dynamic>> getEventParticipants(
    int eventId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/participants'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Approve a participant's request to join a private/invite-only event.
  static Future<Map<String, dynamic>> approveParticipant(
    int eventId,
    int participantUserId,
    int organizerUserId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl.replaceAll(
              '/api/auth', '/api/events/$eventId/participants/$participantUserId/approve'),
        ),
        headers: headers,
        body: jsonEncode({'organizerUserId': organizerUserId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Check whether a specific user has already joined an event and their status.
  static Future<Map<String, dynamic>> getEventParticipationStatus(
    int eventId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        AuthService.baseUrl
            .replaceAll('/api/auth', '/api/events/$eventId/participation'),
      ).replace(queryParameters: {'userId': userId.toString()});
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  /// Save / bookmark an event for later.
  static Future<Map<String, dynamic>> saveEventBookmark(
    int eventId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/save'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Remove a previously saved bookmark for an event.
  static Future<Map<String, dynamic>> unsaveEventBookmark(
    int eventId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/unsave'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Retrieve all events saved/bookmarked by a user.
  static Future<Map<String, dynamic>> getSavedEvents(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/saved/$userId'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Check whether a user has bookmarked a specific event.
  static Future<Map<String, dynamic>> isEventSaved(
    int eventId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        AuthService.baseUrl
            .replaceAll('/api/auth', '/api/events/$eventId/saved'),
      ).replace(queryParameters: {'userId': userId.toString()});
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  /// Fetch the top-level comments (with nested replies) for an event.
  static Future<Map<String, dynamic>> getEventComments(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/comments'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Post a new comment or a reply to an existing comment ([parentId]) on an event.
  static Future<Map<String, dynamic>> addEventComment(
    int eventId,
    int userId,
    String text, {
    int? parentId,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'userId': userId,
        'text': text,
      };
      if (parentId != null) body['parentId'] = parentId;

      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/comments'),
        ),
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Pin a comment so it appears at the top of the comment list (organizer only).
  static Future<Map<String, dynamic>> pinEventComment(
    int commentId,
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl.replaceAll(
              '/api/auth', '/api/events/comments/$commentId/pin'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Add or toggle a reaction (default 'like') on a comment.
  static Future<Map<String, dynamic>> reactToEventComment(
    int commentId,
    int userId, {
    String reaction = 'like',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl.replaceAll(
              '/api/auth', '/api/events/comments/$commentId/react'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId, 'reaction': reaction}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Gallery ───────────────────────────────────────────────────────────────

  /// Retrieve the photo gallery for an event.
  static Future<Map<String, dynamic>> getEventGallery(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/gallery'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Add a photo to an event's gallery (participants / organizer).
  static Future<Map<String, dynamic>> addEventGalleryImage(
    int eventId,
    int userId,
    String imageUrl,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/gallery'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId, 'imageUrl': imageUrl}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Invitations ───────────────────────────────────────────────────────────

  /// Send an invitation to [inviteeId] for a private/invite-only event.
  static Future<Map<String, dynamic>> sendEventInvitation(
    int eventId,
    int inviterId,
    int inviteeId,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/invite'),
        ),
        headers: headers,
        body: jsonEncode({
          'inviterId': inviterId,
          'inviteeId': inviteeId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch all invitations sent for a specific event.
  static Future<Map<String, dynamic>> getEventInvitations(int eventId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl
              .replaceAll('/api/auth', '/api/events/$eventId/invitations'),
        ),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  /// Fetch all pending/responded event invitations for a user.
  static Future<Map<String, dynamic>> getMyEventInvitations(
    int userId,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
        AuthService.baseUrl
            .replaceAll('/api/auth', '/api/events/invitations'),
      ).replace(queryParameters: {'userId': userId.toString()});
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Respond to an event invitation.
  /// [status] must be 'accepted' or 'declined'.
  static Future<Map<String, dynamic>> respondEventInvitation(
    int invitationId,
    String status,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse(
          AuthService.baseUrl.replaceAll(
              '/api/auth', '/api/events/invitations/$invitationId'),
        ),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Announcements ─────────────────────────────────────────────────────────

  /// Send a push-style announcement message to all participants of an event.
  static Future<Map<String, dynamic>> sendEventAnnouncement(
    int eventId,
    int userId,
    String message,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl.replaceAll(
              '/api/auth', '/api/events/$eventId/announce'),
        ),
        headers: headers,
        body: jsonEncode({'userId': userId, 'message': message}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  //friend request
  static Future<Map<String, dynamic>> sendFriendRequest(int receiverId) async {
    try {
      final headers = await _getHeaders();
      final senderId = await AuthService.getUserId();
      if (senderId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/friend-request')}'),
        headers: headers,
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFriendStatus(int targetUserId) async {
    try {
      final headers = await _getHeaders();
      final userId = await AuthService.getUserId();
      if (userId == null) return {'success': false, 'message': 'Not logged in'};

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/friend-status')}?userId=$userId&targetUserId=$targetUserId'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> respondFriendRequest(int requestId, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/friend-request/$requestId/respond')}'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getFriendRequests(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl.replaceAll('/api/auth', '/api/social/friend-requests/$userId')}'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

}


