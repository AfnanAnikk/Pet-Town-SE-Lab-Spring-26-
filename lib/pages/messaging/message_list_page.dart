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

  Future<void> _showNewMessageSheet() async {
    final res = await ApiService.getAllUsers();
    if (!res['success'] || res['data'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load users')),
        );
      }
      return;
    }

    final List<dynamic> allUsers = (res['data'] as List)
        .where((u) => u['id'] != _currentUserId)
        .toList();

    if (!mounted) return;

    final TextEditingController searchCtrl = TextEditingController();
    List<dynamic> filtered = List.from(allUsers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'New Message',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3293B3)),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (q) {
                          setSheetState(() {
                            filtered = allUsers.where((u) {
                              final name = (u['username'] ?? u['email'] ?? '').toLowerCase();
                              return name.contains(q.toLowerCase());
                            }).toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final user = filtered[i];
                                final name = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
                                final imageNumber = (user['id'] % 10) + 1;
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundImage: AssetImage('assets/images/p$imageNumber.png'),
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                          otherUserId: user['id'],
                                          otherUserName: name,
                                          otherUserImage: 'assets/images/p$imageNumber.png',
                                        ),
                                      ),
                                    ).then((_) => _fetchConversations());
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
                    onTap: _showNewMessageSheet,
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
                        child: Text("No conversations yet.\nTap 'New Message' to start chatting!", 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
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
