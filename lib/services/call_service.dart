import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/app_navigator.dart';
import 'auth_service.dart';
import 'api_service.dart';
import '../pages/messaging/call_page.dart';

class CallService {
  static IO.Socket? _socket;
  static int? _currentUserId;
  static String _currentUserName = 'User';

  static OverlayEntry? _incomingCallOverlay;
  static Timer? _callTimeoutTimer;

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    _currentUserId = await AuthService.getUserId();
    if (_currentUserId == null) return;

    final profileRes = await AuthService.getProfile(_currentUserId!);

    if (profileRes['success'] == true && profileRes['data'] != null) {
      final user = profileRes['data']['user'] ?? profileRes['data'];

      _currentUserName =
          user['display_name'] ?? user['username'] ?? user['email'] ?? 'User';
    }

    final backendUrl = AuthService.baseUrl.replaceAll('/api/auth', '');

    _socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Global call socket connected: $_currentUserId');
      _socket!.emit('join_chat', _currentUserId);
    });

    _socket!.on('incoming_call', (data) {
      _showIncomingCallPopup(data);
    });

    _socket!.on('call_declined', (data) {
      debugPrint('Call declined: $data');
    });

    _socket!.on('call_missed', (data) {
      debugPrint('Call missed: $data');
    });

    _isInitialized = true;
  }

  static void startCall({
    required int receiverId,
    required bool isVideo,
  }) {
    if (_socket == null || _currentUserId == null) return;

    final sortedIds = [_currentUserId!, receiverId]..sort();
    final callId = 'room_${sortedIds[0]}_${sortedIds[1]}';

    _socket!.emit('start_call', {
      'caller_id': _currentUserId,
      'receiver_id': receiverId,
      'call_id': callId,
      'is_video': isVideo,
      'caller_name': _currentUserName,
    });

    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          callId: callId,
          currentUserId: _currentUserId.toString(),
          currentUserName: _currentUserName,
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  static void _showIncomingCallPopup(dynamic data) {
    final context = navigatorKey.currentContext;
    final overlay = navigatorKey.currentState?.overlay;

    if (context == null || overlay == null || _currentUserId == null) return;

    _removeIncomingCallPopup();

    final int callerId = data['caller_id'];
    final String callId = data['call_id'];
    final bool isVideo = data['is_video'] == true;
    final String callerName = data['caller_name'] ?? 'Someone';

    _incomingCallOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 55,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFE6E6E6),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF3293B3),
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isVideo
                              ? 'Incoming video call'
                              : 'Incoming voice call',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF374957),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          callerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  InkWell(
                    onTap: () {
                      _declineCall(
                        callerId: callerId,
                        callId: callId,
                        isVideo: isVideo,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                  ),

                  InkWell(
                    onTap: () {
                      _acceptCall(
                        callId: callId,
                        isVideo: isVideo,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.call,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_incomingCallOverlay!);

    _callTimeoutTimer = Timer(const Duration(seconds: 30), () {
      _missCall(
        callerId: callerId,
        callId: callId,
        isVideo: isVideo,
      );
    });
  }

  static void _acceptCall({
    required String callId,
    required bool isVideo,
  }) {
    _removeIncomingCallPopup();

    final context = navigatorKey.currentContext;
    if (context == null || _currentUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          callId: callId,
          currentUserId: _currentUserId.toString(),
          currentUserName: _currentUserName,
          isVideoCall: isVideo,
        ),
      ),
    );
  }

  static Future<void> _declineCall({
    required int callerId,
    required String callId,
    required bool isVideo,
  }) async {
    _removeIncomingCallPopup();

    final message = isVideo ? 'Video call declined' : 'Voice call declined';

    _socket?.emit('call_declined', {
      'caller_id': callerId,
      'receiver_id': _currentUserId,
      'call_id': callId,
      'message': message,
    });

    if (_currentUserId != null) {
      await ApiService.sendMessage(
        _currentUserId!,
        callerId,
        message,
      );
    }
  }

  static Future<void> _missCall({
    required int callerId,
    required String callId,
    required bool isVideo,
  }) async {
    _removeIncomingCallPopup();

    final message = isVideo ? 'Missed video call' : 'Missed voice call';

    _socket?.emit('call_missed', {
      'caller_id': callerId,
      'receiver_id': _currentUserId,
      'call_id': callId,
      'message': message,
    });

    if (_currentUserId != null) {
      await ApiService.sendMessage(
        _currentUserId!,
        callerId,
        message,
      );
    }
  }

  static void _removeIncomingCallPopup() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;

    _incomingCallOverlay?.remove();
    _incomingCallOverlay = null;
  }

  static void dispose() {
    _removeIncomingCallPopup();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isInitialized = false;
  }
}