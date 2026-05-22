import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'chat_page.dart';

class MessageListPage extends StatefulWidget {
  const MessageListPage({super.key});

  @override
  State<MessageListPage> createState() => _MessageListPageState();
}

class _MessageListPageState extends State<MessageListPage> {
  bool _isLoading = true;
  List<dynamic> _conversations = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _currentUserId = userId;
    final res = await ApiService.getConversations(userId);
    
    if (res['success'] && res['data'] != null) {
      setState(() {
        _conversations = res['data'];
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Message',
          style: TextStyle(
            color: Color(0xFF3293B3),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchConversations,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // New Message Row
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mark_email_unread_outlined, size: 32, color: Color(0xFF2C3E50)),
                    title: const Text(
                      'New Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                    ),
                    onTap: () {
                      // Navigate to contact selection
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Invite Friends Row
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Color(0xFF5C6A79)),
                    ),
                    title: const Text(
                      'Invite your friends',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                    ),
                    subtitle: const Text(
                      'Connect to start chatting',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  
                  // Conversations
                  if (_conversations.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text("No conversations yet.", style: TextStyle(color: Colors.grey)),
                      ),
                    ),

                  ..._conversations.map((conv) {
                    final otherName = conv['other_user_name'] ?? conv['other_user_email']?.split('@')[0] ?? 'User';
                    final lastMsg = conv['last_message'] ?? 'Start chatting...';
                    final isMe = conv['last_sender_id'] == _currentUserId;
                    final prefix = isMe ? 'You : ' : '';
                    final isRead = conv['is_read'] == 1 || conv['is_read'] == true;
                    final showUnreadDot = !isMe && !isRead;

                    // Pseudo-random avatar generation based on ID
                    final imageNumber = (conv['other_user_id'] % 10) + 1;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage('assets/images/p$imageNumber.png'),
                        backgroundColor: Colors.grey.shade200,
                      ),
                      title: Text(
                        otherName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                      ),
                      subtitle: Text(
                        '$prefix$lastMsg',
                        style: TextStyle(
                          fontSize: 14,
                          color: showUnreadDot ? Colors.black87 : Colors.grey,
                          fontWeight: showUnreadDot ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: showUnreadDot
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3293B3),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              conversationId: conv['conversation_id'],
                              otherUserId: conv['other_user_id'],
                              otherUserName: otherName,
                              otherUserImage: 'assets/images/p$imageNumber.png',
                            ),
                          ),
                        ).then((_) => _fetchConversations());
                      },
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
