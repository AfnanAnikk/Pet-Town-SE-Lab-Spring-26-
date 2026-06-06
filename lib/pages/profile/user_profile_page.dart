import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../auth/login_page.dart';
import 'user_history_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../home/post_detail_page.dart';
import '../messaging/chat_page.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class UserProfilePage extends StatefulWidget {
  final int? userId;
  const UserProfilePage({super.key, this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  List<dynamic> _posts = [];
  List<dynamic> _savedPosts = [];
  int _postCount = 0;
  bool _isOwnProfile = true;
  int? _loggedInUserId;
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  String _friendStatus = 'none';
  int? _friendRequestId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    _loggedInUserId = await AuthService.getUserId();
    
    final targetUserId = widget.userId ?? _loggedInUserId;
    _isOwnProfile = (targetUserId == _loggedInUserId);

    if (targetUserId != null) {
      final result = await AuthService.getProfile(targetUserId);
      if (result['success']) {
        setState(() {
          _user = result['data']['user'];
          _postCount = result['data']['postCount'];
          _posts = result['data']['posts'];
        });
        _fetchSavedPosts(targetUserId);
        await _loadFollowData(targetUserId);
      }
    }
    setState(() => _isLoading = false);
  }

  void _contactUser() {
    if (_loggedInUserId == null || _user == null) return;
    
    final otherUserId = _user!['id'] as int;
    final otherUserName = _user!['display_name'] ?? _user!['username'] ?? 'User';
    final imageNumber = (otherUserId % 10) + 1;
    final otherUserImage = 'assets/images/p$imageNumber.png';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserImage: otherUserImage,
        ),
      ),
    );
  }

  Future<void> _fetchSavedPosts(int userId) async {
    final res = await ApiService.getSavedPosts(userId);
    if (res['success'] && mounted) {
      setState(() {
        _savedPosts = res['data'];
      });
    }
  }

  Future<void> _loadFollowData(int targetUserId) async {
    final countsRes = await ApiService.getFollowCounts(targetUserId);

    if (countsRes['success'] && mounted) {
      setState(() {
        _followersCount = countsRes['data']['followersCount'] ?? 0;
        _followingCount = countsRes['data']['followingCount'] ?? 0;
      });
    }

    if (!_isOwnProfile) {
      final statusRes = await ApiService.getFollowStatus(targetUserId);

      if (statusRes['success'] && mounted) {
        setState(() {
          _isFollowing = statusRes['data']['isFollowing'] ?? false;
        });
      }

      final friendRes = await ApiService.getFriendStatus(targetUserId);
      
      if (friendRes['success'] && mounted) {
        final data = friendRes['data'];
        setState(() {
          _friendStatus = data['status'] ?? 'none';
          _friendRequestId = data['request']?['id'];
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_user == null) return;

    final targetUserId = _user!['id'] as int;

    final res = _isFollowing
        ? await ApiService.unfollowUser(targetUserId)
        : await ApiService.followUser(targetUserId);

    if (res['success'] && mounted) {
      setState(() {
        _isFollowing = !_isFollowing;
        _followersCount += _isFollowing ? 1 : -1;
      });
    }
  }

  

  void _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _editName() async {
    if (_user == null) return;
    
    final controller = TextEditingController(text: _user!['display_name'] ?? _user!['username'] ?? '');
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => _isLoading = true);
      final userId = await AuthService.getUserId();
      if (userId != null) {
        await AuthService.updateProfile(userId, newName);
        await _loadProfile();
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _isLoading = true);
      final uploadRes = await ApiService.uploadImage(picked.path);
      if (uploadRes['success']) {
        final userId = await AuthService.getUserId();
        if (userId != null) {
          final displayName = _user?['display_name'] ?? _user?['username'] ?? '';
          await AuthService.updateProfile(userId, displayName, profilePictureUrl: uploadRes['data']['url']);
          await _loadProfile();
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadRes['message'])));
      }
    }
  }

  Future<void> _handleFriendAction() async {
    if (_user == null) return;

    final targetUserId = _user!['id'] as int;

    if (_friendStatus == 'none') {
      final res = await ApiService.sendFriendRequest(targetUserId);

      if (res['success'] && mounted) {
        setState(() {
          _friendStatus = 'pending_sent';
          _friendRequestId = res['data']?['requestId'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent')),
        );
      }
      return;
    }

    if (_friendStatus == 'pending_received' && _friendRequestId != null) {
      final res = await ApiService.respondFriendRequest(_friendRequestId!, 'accepted');

      if (res['success'] && mounted) {
        setState(() {
          _friendStatus = 'friends';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayName = _user?['display_name'] ?? _user?['username'] ?? 'No Name Set';
    final handle = '@${_user?['username'] ?? 'user'}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: !_isOwnProfile 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: _isOwnProfile 
            ? [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.black, size: 28),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserHistoryPage()));
                  },
                  tooltip: 'Booking & Order History',
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red, size: 28),
                  onPressed: _handleLogout,
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // User Avatar
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          image: DecorationImage(
                            image: (_user?['profile_picture_url'] != null && _user!['profile_picture_url'].isNotEmpty)
                                ? NetworkImage(_user!['profile_picture_url'])
                                : const AssetImage('assets/images/user1.png') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (_isOwnProfile)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3293B3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                      ),
                      if (_isOwnProfile)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                          onPressed: _editName,
                        ),
                    ],
                  ),
                  Text(
                    handle,
                    style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatColumn('$_postCount', 'Pins'),
                      const SizedBox(width: 40),
                      _buildStatColumn('$_followersCount', 'Followers'),
                      const SizedBox(width: 40),
                      _buildStatColumn('$_followingCount', 'Following'),
                    ],
                  ),
                  if (!_isOwnProfile) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(
                            _isFollowing ? Icons.check : Icons.person_add_alt_1,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            _isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? const Color.fromARGB(255, 63, 151, 180) : const Color(0xFF3293B3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: (_friendStatus == 'pending_sent' || _friendStatus == 'friends')
                              ? null
                              : _handleFriendAction,
                          icon: Icon(
                            _friendStatus == 'friends'
                                ? Icons.people
                                : _friendStatus == 'pending_sent'
                                    ? Icons.hourglass_top
                                    : _friendStatus == 'pending_received'
                                        ? Icons.person_add_alt_1
                                        : Icons.person_add,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            _friendStatus == 'friends'
                                ? 'Friends'
                                : _friendStatus == 'pending_sent'
                                    ? 'Requested'
                                    : _friendStatus == 'pending_received'
                                        ? 'Accept'
                                        : 'Add Friend',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3293B3),
                            disabledBackgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _contactUser,
                          icon: const Icon(Icons.message_rounded, color: Colors.white, size: 18),
                          label: const Text(
                            'Message',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3293B3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: 'Created'),
                    Tab(text: 'Saved'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreatedTab(),
            _buildSavedTab(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCreatedTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No pins created yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          String imageUrl = post['image_path'] ?? 'assets/images/post_placeholder.png';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(post: PostModel.fromJson(post)),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.grey.shade200,
                height: (index % 3 + 2) * 80.0, // Staggered height
                child: imageUrl.startsWith('http') 
                  ? Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedTab() {
    if (_savedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No saved pins yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _savedPosts.length,
        itemBuilder: (context, index) {
          final post = _savedPosts[index];
          String imageUrl = post['image_path'] ?? 'assets/images/post_placeholder.png';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(post: PostModel.fromJson(post)),
                ),
              ).then((_) {
                // Refresh if a post was unsaved
                final userId = _user?['id'];
                if (userId != null) _fetchSavedPosts(userId);
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: Colors.grey.shade200,
                height: (index % 3 + 2) * 80.0, // Staggered height
                child: imageUrl.startsWith('http') 
                  ? Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
