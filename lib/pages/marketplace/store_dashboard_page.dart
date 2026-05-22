import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'add_product_page.dart';
import 'package:intl/intl.dart';

class StoreDashboardPage extends StatefulWidget {
  const StoreDashboardPage({super.key});

  @override
  State<StoreDashboardPage> createState() => _StoreDashboardPageState();
}

class _StoreDashboardPageState extends State<StoreDashboardPage> {
  bool _isLoading = true;
  int? _userId;
  Map<String, dynamic>? _storeData;
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  
  // Tab index: 0 = Products, 1 = Orders
  int _currentTab = 0; 

  final _storeNameController = TextEditingController();
  final _storeDescController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  File? _bannerImage;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _bannerImage = File(picked.path);
      });
    }
  }

  Future<void> _fetchStoreData() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    _userId = userId;

    final storeRes = await ApiService.getStoreByUserId(userId);
    if (storeRes['success']) {
      final store = storeRes['data'];
      final productsRes = await ApiService.getStoreProducts(store['id']);
      final ordersRes = await ApiService.getStoreOrders(store['id']);
      
      setState(() {
        _storeData = store;
        _products = productsRes['success'] ? productsRes['data'] : [];
        _orders = ordersRes['success'] ? ordersRes['data'] : [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createStore() async {
    if (_storeNameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    String? bannerUrl;
    if (_bannerImage != null) {
      final uploadRes = await ApiService.uploadImage(_bannerImage!.path);
      if (uploadRes['success']) {
        bannerUrl = uploadRes['data']['url'];
      }
    }

    final res = await ApiService.createStore({
      'userId': _userId,
      'name': _storeNameController.text.trim(),
      'description': _storeDescController.text.trim(),
      'bannerUrl': bannerUrl,
      'location': _locationController.text.trim(),
      'contactInfo': _contactController.text.trim(),
    });

    if (res['success']) {
      await _fetchStoreData();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    final res = await ApiService.updateOrderStatus(orderId, status);
    if (res['success']) {
      _fetchStoreData();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_storeData == null) {
      // Create Store View
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Set Up Your Shop', style: TextStyle(color: Color(0xFF374957))),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Store Banner', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickBannerImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _bannerImage != null
                      ? Image.file(_bannerImage!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('Upload Shop Banner', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Store Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g. Happy Paws Shop',
                ),
              ),
              const SizedBox(height: 24),
              const Text('Store Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _storeDescController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'Tell customers about your products...',
                ),
              ),
              const SizedBox(height: 24),
              const Text('City / Location', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g. Dhaka, Gulshan',
                ),
              ),
              const SizedBox(height: 24),
              const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: 'e.g. +880 17...',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3293B3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Open Store', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    }

    // Dashboard View
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_storeData!['name'], style: const TextStyle(color: Color(0xFF374957))),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {},
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Products', _products.length.toString()),
                  _buildStatCard('Orders', _orders.length.toString()),
                  _buildStatCard('Rating', _storeData!['rating'].toString()),
                ],
              ),
            ),
          ),
          
          // Custom Tab Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 0 ? const Color(0xFF3293B3) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _currentTab == 0 ? const Color(0xFF3293B3) : Colors.grey.shade300),
                        ),
                        child: Center(child: Text('Products', style: TextStyle(color: _currentTab == 0 ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 1 ? const Color(0xFF3293B3) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _currentTab == 1 ? const Color(0xFF3293B3) : Colors.grey.shade300),
                        ),
                        child: Center(child: Text('Orders', style: TextStyle(color: _currentTab == 1 ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_currentTab == 0) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Manage Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddProductPage(storeId: _storeData!['id'])),
                        ).then((_) => _fetchStoreData());
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3293B3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = _products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('৳${p['price']} • Stock: ${p['quantity']}'),
                      trailing: Switch(
                        value: p['is_active'] == 1 || p['is_active'] == true,
                        onChanged: (val) async {
                          await ApiService.updateProduct(p['id'], {...p, 'isActive': val});
                          _fetchStoreData();
                        },
                        activeColor: const Color(0xFF3293B3),
                      ),
                    ),
                  );
                },
                childCount: _products.length,
              ),
            ),
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = _orders[index];
                  final items = order['items'] as List<dynamic>? ?? [];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order['status'] == 'pending' ? Colors.orange.shade100 : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (order['status'] ?? 'pending').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: order['status'] == 'pending' ? Colors.orange.shade800 : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text('Customer: ${order['customer_name']}'),
                          Text('Address: ${order['delivery_address']}'),
                          const SizedBox(height: 8),
                          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((i) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4),
                            child: Text('${i['quantity']}x ${i['product_name']} (৳${i['price']})'),
                          )),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('৳${order['total_price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3293B3))),
                            ],
                          ),
                          if (order['status'] == 'pending') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateOrderStatus(order['id'], 'preparing'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    child: const Text('Accept & Prepare', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (order['status'] == 'preparing') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateOrderStatus(order['id'], 'sent for delivery'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Send for Delivery', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                childCount: _orders.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3293B3))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
