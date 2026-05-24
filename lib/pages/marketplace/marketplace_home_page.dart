import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'store_dashboard_page.dart';
import 'cart_page.dart';
import 'shop_details_page.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class MarketplaceHomePage extends StatefulWidget {
  const MarketplaceHomePage({super.key});

  @override
  State<MarketplaceHomePage> createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> {
  bool _isLoading = true;
  List<dynamic> _stores = [];
  String _searchQuery = '';
  String _selectedCategory = ''; // empty = no filter

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.pets},
    {'name': 'Toys', 'icon': Icons.sports_tennis},
    {'name': 'Accessories', 'icon': Icons.checkroom},
    {'name': 'Medicine', 'icon': Icons.medical_services},
  ];

  @override
  void initState() {
    super.initState();
    _fetchStores();
    CartService().addListener(_updateState);
  }

  @override
  void dispose() {
    CartService().removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchStores() async {
    final result = await ApiService.getAllStores();
    if (result['success']) {
      setState(() {
        _stores = result['data'];
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter stores based on search query AND selected category
    final filteredStores = _stores.where((s) {
      final name = s['name'].toString().toLowerCase();
      final loc = s['location']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(q) || loc.contains(q);

      // Category filter: match the store's category field (case-insensitive)
      final storeCategory = s['category']?.toString().toLowerCase() ?? '';
      final matchesCategory = _selectedCategory.isEmpty ||
          storeCategory.contains(_selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pet Marketplace',
          style: TextStyle(
            color: Color(0xFF374957),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black, size: 26),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                },
              ),
              if (CartService().items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '${CartService().items.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Search Bar & Banner
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.grey),
                              hintText: 'Search for shops or locations...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Promotional Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3293B3), Color(0xFF3FA9F5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Save up to 50%',
                                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'On premium dog food',
                                      style: TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Shop Now',
                                        style: TextStyle(color: Color(0xFF3293B3), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.pets, color: Colors.white54, size: 64),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat['name'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Tap same category again → deselect
                                  _selectedCategory =
                                      isSelected ? '' : cat['name'] as String;
                                });
                              },
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF3293B3)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? const Color(0xFF3293B3).withOpacity(0.35)
                                              : Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      cat['icon'] as IconData,
                                      color: isSelected ? Colors.white : const Color(0xFF3293B3),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    cat['name'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF3293B3)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nearby Shops Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategory.isEmpty
                              ? 'Nearby Shops'
                              : '$_selectedCategory Shops',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374957),
                          ),
                        ),
                        if (_selectedCategory.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategory = ''),
                            child: const Text(
                              'Clear filter',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3293B3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Shops Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: filteredStores.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('No nearby shops found.')),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final store = filteredStores[index];
                              return _buildStoreCard(store);
                            },
                            childCount: filteredStores.length,
                          ),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
            bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildStoreCard(dynamic store) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopDetailsPage(store: store),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Banner
            Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: store['banner_url'] != null
                  ? Image.network(store['banner_url'], fit: BoxFit.cover)
                  : const Icon(Icons.store, color: Colors.grey, size: 50),
            ),
            
            // Store Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                store['location'] ?? 'Location not provided',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store['category'] ?? 'General',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3293B3), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${store['rating'] ?? 'New'}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                      ],
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
