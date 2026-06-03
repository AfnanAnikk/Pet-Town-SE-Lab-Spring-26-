import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class RegisteredPage extends StatefulWidget {
  const RegisteredPage({super.key});

  @override
  State<RegisteredPage> createState() => _RegisteredPageState();
}

class _RegisteredPageState extends State<RegisteredPage> {
  bool _isLoadingRequests = true;
  List<dynamic> _myRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchMyAdoptionRequests();
  }

  Future<void> _fetchMyAdoptionRequests() async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      setState(() {
        _isLoadingRequests = false;
      });
      return;
    }

    final res = await ApiService.getUserAdoptionRequests(userId);

    if (mounted) {
      setState(() {
        _myRequests = res['success'] == true && res['data'] != null ? res['data'] : [];
        _isLoadingRequests = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              indicatorColor: const Color(0xFF3293B3),
              labelColor: const Color(0xFF3293B3),
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Booked Pets'),
                Tab(text: 'My Re-Homes'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBookedPetsTab(),
                const Center(child: Text("You haven't placed any pets for re-homing.")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedPetsTab() {
    if (_isLoadingRequests) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3293B3)),
      );
    }

    if (_myRequests.isEmpty) {
      return Center(
        child: Text(
          "You haven't booked any pets yet.",
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyAdoptionRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (context, index) {
          final request = _myRequests[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    request['image_url'] ?? '',
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 78,
                      height: 78,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.pets, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['pet_name'] ?? 'Unknown Pet',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF374957),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request['pet_age'] ?? ''} • ${request['pet_breed'] ?? ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _statusChip(request['request_status'] ?? 'pending'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3293B3),
        ),
      ),
    );
  }
}