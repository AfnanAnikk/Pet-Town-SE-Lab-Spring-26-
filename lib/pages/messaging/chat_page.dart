import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'call_page.dart';
import '../../services/call_service.dart';
import '../profile/user_profile_page.dart';

class ChatPage extends StatefulWidget {
  final int? conversationId;
  final int otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String? initialText;

  const ChatPage({
    super.key,
    this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    this.initialText,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  List<dynamic> _messages = [];
  int? _currentUserId;
  String? _otherUserProfilePictureUrl;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();

    if (widget.otherUserImage.startsWith('http://') ||
        widget.otherUserImage.startsWith('https://')) {
      _otherUserProfilePictureUrl = widget.otherUserImage;
    }
    
    if (widget.initialText != null) {
      _messageController.text = widget.initialText!;
    }

    _initChat();
    _loadOtherUserProfilePicture();
  }

  Future<void> _loadOtherUserProfilePicture() async {
    final res = await AuthService.getProfile(widget.otherUserId);

    if (res['success'] == true && res['data'] != null && mounted) {
      final user = res['data']['user'] ?? res['data'];

      setState(() {
        _otherUserProfilePictureUrl = user['profile_picture_url'];
      });
    }
  }

  Future<void> _initChat() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _currentUserId = userId;

    // If no conversationId passed, look for an existing one with this user
    int? resolvedConversationId = widget.conversationId;
    if (resolvedConversationId == null) {
      final convsRes = await ApiService.getConversations(userId);
      if (convsRes['success'] && convsRes['data'] != null) {
        final List<dynamic> convs = convsRes['data'];
        final existing = convs.firstWhere(
          (c) => c['other_user_id'] == widget.otherUserId,
          orElse: () => null,
        );
        if (existing != null) {
          resolvedConversationId = existing['conversation_id'];
        }
      }
    }

    if (resolvedConversationId != null) {
      final res = await ApiService.getMessages(resolvedConversationId);
      if (res['success']) {
        setState(() {
          _messages = res['data'];
        });
      }
    }

    _connectSocket();

    setState(() {
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _connectSocket() {
    // Determine backend URL (removing /api/auth)
    final backendUrl = AuthService.baseUrl.replaceAll('/api/auth', '');
    
    _socket = IO.io(backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      _socket.emit('join_chat', _currentUserId);
    });

    _socket.on('receive_message', (data) {
      if (mounted) {
        // Only append if it belongs to this conversation (or if we are just chatting with the same person)
        if (data['sender_id'] == widget.otherUserId || data['sender_id'] == _currentUserId) {
           setState(() {
             _messages.add(data);
           });
           _scrollToBottom();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _socket.disconnect();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _messageController.clear();

    // Optimistically add to UI, but the socket emit will also send it back to us,
    // so we rely on the API response to avoid duplicates, or just rely on the API.
    final res = await ApiService.sendMessage(_currentUserId!, widget.otherUserId, text);
    if (res['success']) {
      // The socket server emits 'receive_message' to both sender and receiver, 
      // so it will be added to the list automatically by the socket listener.
      _scrollToBottom();
    }
  }

  void _startCall({required bool isVideo}) {
    if (_currentUserId == null) return;

    CallService.startCall(
      receiverId: widget.otherUserId,
      isVideo: isVideo,
    );
  }

  ImageProvider? _getOtherUserImageProvider() {
    final image = _otherUserProfilePictureUrl?.trim();

    if (image == null || image.isEmpty) {
      return null;
    }

    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(userId: widget.otherUserId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _getOtherUserImageProvider(),
                child: _getOtherUserImageProvider() == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Color(0xFF374957),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF3293B3), size: 24),
            onPressed: () => _startCall(isVideo: false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF3293B3), size: 28),
            onPressed: () => _startCall(isVideo: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['sender_id'] == _currentUserId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF3293B3) : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Text(
                              msg['text'],
                              style: TextStyle(
                                color: isMe ? Colors.white : const Color(0xFF374957),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Message Input Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.grey, size: 28),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3293B3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
