import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../vet/vet_list_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMorePosts();
    
    // Add scroll listener for endless scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMorePosts();
      }
    });
  }

  void _loadMorePosts() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay then append dummy data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _posts.addAll(PostModel.generateDummyPosts(
            10, 
            startIndex: _currentPage * 10,
          ));
          _currentPage++;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildFeatureIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Icon(icon, size: 28, color: Colors.black87),
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
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.black, size: 28),
            onPressed: () {},
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
                right: 60,
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const VetListPage()),
                            );
                            setState(() {
                              _showFeatureMenu = false;
                            });
                          },
                          child: _buildFeatureIcon(Icons.medical_information_outlined, 'Pet Vet'),
                        ),
                        _buildFeatureIcon(Icons.shopping_bag_outlined, 'Marketplace'),
                        _buildFeatureIcon(Icons.volunteer_activism_outlined, 'Adoption'),
                        _buildFeatureIcon(Icons.event_outlined, 'Events'),
                        _buildFeatureIcon(Icons.cut_outlined, 'Grooming'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // Toggle feature menu
            setState(() {
              _showFeatureMenu = !_showFeatureMenu;
            });
          } else {
            // Hide menu and select tab
            setState(() {
              _showFeatureMenu = false;
              _selectedIndex = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 28),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.pets, size: 26),
            label: 'Features',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none, size: 28),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFE0E0E0),
                child: Icon(Icons.person, size: 16, color: Colors.grey),
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
