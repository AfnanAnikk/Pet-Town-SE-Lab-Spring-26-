import 'package:flutter/material.dart';
import 'salon_provider_profile_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../messaging/chat_page.dart';
import '../messaging/message_list_page.dart';


class SalonDashboardPage extends StatefulWidget {
  const SalonDashboardPage({super.key});

  @override
  State<SalonDashboardPage> createState() => _SalonDashboardPageState();
}

class _SalonDashboardPageState extends State<SalonDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _errorMessage = '';
  String? _salonId;
  List<dynamic> _vouchers = [];
  bool _isVouchersLoading = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _messageClient(dynamic booking) {
    final clientUserIdRaw = booking['user_id'];
    final clientUserId = clientUserIdRaw is int
        ? clientUserIdRaw
        : int.tryParse(clientUserIdRaw.toString());

    if (clientUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: clientUserId,
          otherUserName: booking['user_name'] ?? booking['user_email'] ?? 'Client',
          otherUserImage: '',
        ),
      ),
    );
  }

  Future<void> _fetchBookings() async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      setState(() {
        _errorMessage = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    final profileRes = await ApiService.getSalonProfile(userId.toString());

    if (profileRes['success'] && profileRes['data'] != null) {
      _salonId = profileRes['data']['id']?.toString();
      _isVerified = profileRes['data']['is_verified'] == true ||
          profileRes['data']['is_verified'] == 1;
    }

    final result = await ApiService.getProviderSalonBookings(userId.toString());

    if (result['success']) {
      setState(() {
        _bookings = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load bookings';
        _isLoading = false;
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

  Future<void> _updateStatus(String bookingId, String status) async {
    // Optimistic UI update
    final index = _bookings.indexWhere((b) => b['id'].toString() == bookingId);
    if (index != -1) {
      setState(() {
        _bookings[index]['status'] = status;
      });
    }
    
    final result = await ApiService.updateSalonBookingStatus(bookingId, status);
    if (!result['success']) {
      // Revert if failed
      _fetchBookings(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Salon Suite',
          style: TextStyle(
            color: Color(0xFF374957),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 28),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          if (!_isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFFFF4E5),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your salon is currently under review by our admin team. Some features may be limited.',
                      style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedIndex == 0
                ? _buildDashboardContent()
                : _selectedIndex == 1
                    ? _buildVouchersContent()
                    : _selectedIndex == 2
                        ? const MessageListPage(showScaffoldBars: false)
                        : _selectedIndex == 3
                            ? const SalonProviderProfilePage()
                            : const Center(child: Text("Feature coming soon")),
          ),
        ],
      ),
      
      // Business Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3FA9F5),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        elevation: 8,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _fetchVouchers();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.discount_outlined),
            activeIcon: Icon(Icons.discount),
            label: 'Vouchers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Appointments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374957),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: Color(0xFF3FA9F5))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoading 
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                  : _bookings.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No upcoming appointments.")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            return _buildBookingCard(_bookings[index]);
                          },
                        ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking['status'] == 'pending' ? Colors.orange.shade50 : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (booking['status'] ?? 'pending').toUpperCase(),
                  style: TextStyle(
                    color: booking['status'] == 'pending' ? Colors.orange : Colors.green, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Text(
                '${booking['booking_date']?.split('T')?.first ?? ''} • ${booking['slot_time'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE0E0E0),
                child: Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking['user_name'] ?? 'Client', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Pet: ${booking['pet_name'] ?? 'Unknown'}, ${booking['pet_species'] ?? 'Unknown'}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildInfoRow(Icons.content_cut_outlined, 'Service', booking['service'] ?? 'Unknown'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.folder_open_outlined, 'Instructions', booking['reason'] ?? 'None'),
          const SizedBox(height: 16),
          if (booking['status'] == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(booking['id'].toString(), 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(booking['id'].toString(), 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAppointmentDetailsSheet(booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3FA9F5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('View Full Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontFamily: 'Outfit'),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAppointmentDetailsSheet(dynamic booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointment Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3293B3)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('${booking['booking_date']?.split('T')?.first ?? ''} • ${booking['slot_time'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.person_outline, 'Client', booking['user_name'] ?? 'Client'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.pets_outlined, 'Pet', '${booking['pet_name'] ?? ''}, ${booking['pet_species'] ?? ''}, ${booking['pet_sex'] ?? ''}, ${booking['pet_age'] ?? ''}'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.content_cut_outlined, 'Service', booking['service'] ?? 'Unknown'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.folder_open_outlined, 'Instructions', booking['reason'] ?? 'None'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.payments_outlined, 'Payment', booking['payment_method'] ?? 'Unknown'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _messageClient(booking);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF3FA9F5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Message Client',
                      style: TextStyle(color: Color(0xFF3FA9F5)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3FA9F5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchVouchers() async {
    setState(() {
      _isVouchersLoading = true;
    });

    final userId = await AuthService.getUserId();
    if (userId == null) {
      setState(() {
        _errorMessage = 'User not logged in';
        _isVouchersLoading = false;
      });
      return;
    }

    if (_salonId == null) {
      final profileRes = await ApiService.getSalonProfile(userId.toString());
      if (profileRes['success'] && profileRes['data'] != null) {
        _salonId = profileRes['data']['id']?.toString();
      } else {
        setState(() {
          _errorMessage = profileRes['message'] ?? 'Failed to load profile';
          _isVouchersLoading = false;
        });
        return;
      }
    }

    final result = await ApiService.getSalonVouchers(userId.toString()); // providerUserId
    if (result['success']) {
      setState(() {
        _vouchers = result['data'];
        _isVouchersLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load vouchers';
        _isVouchersLoading = false;
      });
    }
  }

  Widget _buildVouchersContent() {
    return _isVouchersLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vouchers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374957),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddVoucherDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Voucher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3FA9F5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _vouchers.isEmpty
                    ? const Center(
                        child: Text(
                          'No vouchers active. Add a unique voucher for your salon!',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _vouchers.length,
                        itemBuilder: (context, index) {
                          final v = _vouchers[index];
                          final expiry = v['expires_at'] != null ? DateTime.tryParse(v['expires_at']) : null;
                          final expiryStr = expiry != null ? '${expiry.day}/${expiry.month}/${expiry.year}' : 'Never';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${v['discount_percent']}%',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                        const Text(
                                          'OFF',
                                          style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['code'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Expires: $expiryStr', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        Text('Uses: ${v['used_count']}/${v['max_uses']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: v['is_active'] == 1 || v['is_active'] == true,
                                        onChanged: (val) async {
                                          // TODO: implement API for voucher update if needed
                                        },
                                        activeColor: const Color(0xFF3FA9F5),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }

  void _showAddVoucherDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final maxUsesController = TextEditingController();
    DateTime? selectedExpiry;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Voucher', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3293B3))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Voucher Code *', hintText: 'e.g. GLOWUP20'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Discount Percent *', hintText: 'e.g. 20'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxUsesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Uses Limit', hintText: 'e.g. 100'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(selectedExpiry == null
                              ? 'No Expiry Date Set'
                              : 'Expires: ${selectedExpiry!.day}/${selectedExpiry!.month}/${selectedExpiry!.year}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedExpiry = picked);
                            }
                          },
                          child: const Text('Select Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3FA9F5)),
                  onPressed: () async {
                    final code = codeController.text.trim().toUpperCase();
                    final discount = int.tryParse(discountController.text) ?? 0;
                    if (code.isEmpty || discount <= 0 || discount > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields (discount 1-100%)')));
                      return;
                    }

                    if (_salonId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salon profile data missing.')));
                      return;
                    }
                    
                    final userId = await AuthService.getUserId();
                    if (userId == null) return;
                    
                    final res = await ApiService.createSalonVoucher(userId.toString(), {
                      'salonId': _salonId,
                      'code': code,
                      'discountPercent': discount,
                      'maxUses': int.tryParse(maxUsesController.text) ?? 100,
                      'expiresAt': selectedExpiry?.toIso8601String(),
                    });

                    if (mounted) Navigator.pop(context);
                    
                    if (res['success']) {
                      _fetchVouchers();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher created successfully!')));
                    } else {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to create voucher')));
                    }
                  },
                  child: const Text('Create', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
