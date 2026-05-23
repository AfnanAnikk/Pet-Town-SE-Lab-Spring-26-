import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'cart_page.dart';

class ShopDetailsPage extends StatefulWidget {
  final dynamic store;
  const ShopDetailsPage({super.key, required this.store});

  @override
  State<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  bool _isLoading = true;
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
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

  Future<void> _fetchProducts() async {
    final result = await ApiService.getStoreProducts(widget.store['id']);
    if (result['success']) {
      setState(() {
        _products = result['data'];
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.store['name'],
          style: const TextStyle(
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
                SliverToBoxAdapter(
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: widget.store['banner_url'] != null
                        ? Image.network(widget.store['banner_url'], fit: BoxFit.cover)
                        : const Icon(Icons.store, color: Colors.grey, size: 64),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Products',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _products.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('This store has no products yet.')),
                          ),
                        )
                      : SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _buildProductCard(product);
                          },
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Container(
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
          Container(
            height: 140,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: product['image_path'] != null
                ? (product['image_path'].toString().startsWith('http')
                    ? Image.network(product['image_path'], fit: BoxFit.cover)
                    : Image.asset(product['image_path'], fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.shopping_bag, color: Colors.grey, size: 40)))
                : const Icon(Icons.shopping_bag, color: Colors.grey, size: 40),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product['price']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3293B3)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      CartService().addItem({
                        'id': product['id'],
                        'name': product['name'],
                        'price': product['price'],
                        'image_path': product['image_path'],
                        'store_id': widget.store['id'],
                        'store_name': widget.store['name'],
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!'), duration: Duration(seconds: 1)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3293B3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
