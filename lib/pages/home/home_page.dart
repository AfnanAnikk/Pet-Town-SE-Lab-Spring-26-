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
          onPressed: () {},
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
              onPressed: () {},
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
                                    MaterialPageRoute(builder: (context) => const VetListPage()),
                                  );
                                  setState(() => _showFeatureMenu = false);
                                },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/adoption.png', width: 28),
                            tooltip: 'Adoption',
                            onTap: () {
                              Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const VetListPage()),
                                  );
                                  setState(() => _showFeatureMenu = false);
                                },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/events.png', width: 28),
                            tooltip: 'Events',
                            onTap: () {
                              Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const VetListPage()),
                                  );
                                  setState(() => _showFeatureMenu = false);
                                },
                          ),
                          _buildFeatureIcon(
                            icon: Image.asset('assets/images/grooming.png', width: 28),
                            tooltip: 'Grooming',
                            onTap: () {
                              Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const VetListPage()),
                                  );
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(255, 124, 124, 124),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // Toggle feature menu
            setState(() {
              _showFeatureMenu = !_showFeatureMenu;
              _selectedIndex = 2;
            },
            );
          } else {
            // Hide menu and select tab
            setState(() {
              _showFeatureMenu = false;
              _selectedIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
                          'assets/images/home.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
            activeIcon: Image.asset(
                          'assets/images/home1.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 28),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
                          'assets/images/features.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
            activeIcon: Image.asset(
                          'assets/images/features1.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
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
