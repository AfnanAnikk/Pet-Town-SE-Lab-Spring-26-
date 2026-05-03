import 'package:flutter/material.dart';
import 'provider_profile_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ProviderDashboardPage extends StatefulWidget {
  const ProviderDashboardPage({super.key});

  @override
  State<ProviderDashboardPage> createState() => _ProviderDashboardPageState();
}

class _ProviderDashboardPageState extends State<ProviderDashboardPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
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

    final result = await ApiService.getVetBookings(userId);
    
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

  Future<void> _updateStatus(int bookingId, String status) async {
    // Optimistic UI update
    final index = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (index != -1) {
      setState(() {
        _bookings[index]['status'] = status;
      });
    }
    
    final result = await ApiService.updateBookingStatus(bookingId, status);
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
          'Business Suite',
          style: TextStyle(
            color: Color(0xFF374957),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFFFF4E5), // Light warning orange
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9800), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your account is currently under review by our admin team. Some features may be limited.',
                    style: TextStyle(color: Color(0xFFE65100), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _selectedIndex == 0 
                ? _buildDashboardContent() 
                : _selectedIndex == 3
                    ? const ProviderProfilePage()
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
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
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
                '${booking['booking_date']} • ${booking['slot_time']}',
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
                    Text('Patient: ${booking['pet_name']}, ${booking['pet_species']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          _buildInfoRow(Icons.medical_services_outlined, 'Concern', booking['concern']),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.folder_open_outlined, 'Reason', booking['reason']),
          const SizedBox(height: 16),
          if (booking['status'] == 'pending') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(booking['id'], 'rejected'),
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
                    onPressed: () => _updateStatus(booking['id'], 'accepted'),
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
            Text('${booking['booking_date']} • ${booking['slot_time']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.person_outline, 'Client', booking['user_name'] ?? 'Client'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.pets_outlined, 'Patient', '${booking['pet_name']}, ${booking['pet_species']}, ${booking['pet_sex']}, ${booking['pet_age']}'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.medical_services_outlined, 'Concern', booking['concern']),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.folder_open_outlined, 'Reason', booking['reason']),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.payments_outlined, 'Payment', booking['payment_method']),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF3FA9F5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Message Client', style: TextStyle(color: Color(0xFF3FA9F5))),
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
                    child: const Text('Start Consultation', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
