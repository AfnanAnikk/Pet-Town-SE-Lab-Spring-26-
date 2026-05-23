import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../vet/vet_list_page.dart';
import '../profile/user_profile_page.dart';
import '../../services/api_service.dart';
import '../messaging/message_list_page.dart';
import '../marketplace/marketplace_home_page.dart';
import '../post/create_post_flow.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<PostModel> _posts = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  // State for the feature pop-up modal
  bool _showFeatureMenu = false;
  int _selectedIndex = 0;

  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    
    // Add scroll listener for endless scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _fetchInitialPosts() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getAllPosts();
    if (result['success']) {
      final List<dynamic> data = result['data'];
      setState(() {
        _posts.clear();
        _posts.addAll(data.map((json) => PostModel.fromJson(json)).toList());
        _isLoading = false;
        _hasMore = false; // We loaded all posts from the db at once
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _loadMorePosts() {
    if (_isLoading || !_hasMore) return;
    
    // For now, getAllPosts fetches everything at once so we just return
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFeatureIcon({
  required Widget icon,
  required String tooltip,
  required VoidCallback onTap,
  }) {
  return GestureDetector(
    onTap: onTap,
    child: Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: icon,
      ),
    ),
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
          icon: const Icon(Icons.add, color: Colors.black, size: 28),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostFlow()),
            );
            if (result == true) {
              _fetchInitialPosts();
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              icon: Image.asset(
                          'assets/images/messaging.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,                       
                        ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MessageListPage()),
                );
              },
            ),
          ),
        ],
        title: const Text(
          'Pet Town',
          style: TextStyle(
            color: Color(0xFF374957),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content (Masonry Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MasonryGridView.count(
                controller: _scrollController,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: _posts[index]);
                },
              ),
            ),
            
            // Overlay to dismiss the menu when tapping outside
            if (_showFeatureMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFeatureMenu = false;
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
              
            // The Pill-shaped Feature Menu
            if (_showFeatureMenu)
              Positioned(
                bottom: 16,
                left: (MediaQuery.of(context).size.width - 300) / 2,
                child: SizedBox(
                  width: 300,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFeatureIcon(
                             icon: Image.asset('assets/images/vet1.png', width: 28),
                             tooltip: 'Pet Vet',
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(builder: (context) => const VetListPage()),
                               );
                               setState(() => _showFeatureMenu = false);
                             },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/marketplace.png', width: 28),
                            tooltip: 'Marketplace',
                            onTap: () {
                              Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MarketplaceHomePage()),
                                  );
                                  setState(() => _showFeatureMenu = false);
                                },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/adoption.png', width: 28),
                            tooltip: 'Adoption',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adoption Feature Coming Soon!')));
                              setState(() => _showFeatureMenu = false);
                            },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/events.png', width: 28),
                            tooltip: 'Events',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Events Feature Coming Soon!')));
                              setState(() => _showFeatureMenu = false);
                            },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/grooming.png', width: 28),
                            tooltip: 'Grooming',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Grooming Feature Coming Soon!')));
                              setState(() => _showFeatureMenu = false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}
