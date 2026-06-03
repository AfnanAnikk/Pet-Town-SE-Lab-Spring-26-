import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../services/api_service.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../profile/user_profile_page.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  bool _isLoading = false;
  List<dynamic> _users = [];
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final res = await ApiService.globalSearch(query.trim());
    if (res['success']) {
      final userList = res['users'] as List? ?? [];
      final postList = res['posts'] as List? ?? [];

      setState(() {
        _users = userList;
        _posts = postList.map((json) => PostModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Search failed')));
      }
    }
  }

  Widget _buildUserAvatar(dynamic user) {
    final profileImageUrl = user['profile_picture_url'];
    final name = user['name'] ?? user['username'] ?? 'User';

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: profileImageUrl != null && profileImageUrl.toString().isNotEmpty
          ? NetworkImage(profileImageUrl.toString())
          : null,
      child: profileImageUrl == null || profileImageUrl.toString().isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            )
          : null,
    );
  }

  Widget _buildAllTab() {
    if (_users.isEmpty && _posts.isEmpty) {
      return const Center(child: Text('No results found.', style: TextStyle(color: Colors.grey)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_users.isNotEmpty) ...[
          const Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: user['id'])));
                  },
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        _buildUserAvatar(user),
                        const SizedBox(height: 8),
                        Text(
                          user['name'] ?? user['username'] ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        if (_posts.isNotEmpty) ...[
          const Text('Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              return PostCard(post: _posts[index]);
            },
          ),
        ]
      ],
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('No users found.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return ListTile(
          leading: _buildUserAvatar(user),
          title: Text(user['name'] ?? user['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(user['email'] ?? ''),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(userId: user['id'])));
          },
        );
      },
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return const Center(child: Text('No posts found.', style: TextStyle(color: Colors.grey)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostCard(post: _posts[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users (@) or posts...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF3293B3)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          ),
                        ),
                        onSubmitted: _performSearch,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF3293B3),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF3293B3),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Users'),
                  Tab(text: 'Posts'),
                ],
              ),
            ),
            
            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(),
                        _buildUsersTab(),
                        _buildPostsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1), // Assuming 1 is search icon
    );
  }
}
