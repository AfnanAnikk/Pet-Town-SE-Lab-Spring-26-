import 'package:flutter/material.dart';
import '../../models/salon_model.dart';
import '../../services/api_service.dart';
import '../../widgets/salon_filter_sheet.dart';
import 'salon_profile_page.dart';
import 'salon_booking_page.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class SalonListPage extends StatefulWidget {
  const SalonListPage({super.key});

  @override
  State<SalonListPage> createState() => _SalonListPageState();
}

class _SalonListPageState extends State<SalonListPage> {
  String? _filterLocation;
  String? _filterConcern;
  String? _filterSpecies;
  List<String> _filterDates = [];

  bool _isLoading = true;
  List<SalonModel> _salons = [];

  @override
  void initState() {
    super.initState();
    _fetchSalons();
  }

  Future<void> _fetchSalons({
    String? location,
    String? concern,
    String? species,
    List<String>? dates,
  }) async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getAllSalons(
      location: location,
      concern: concern,
    );

    if (result['success']) {
      final List<dynamic> data = result['data'];
      setState(() {
        _salons = data.map((json) => SalonModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredSalons = List<SalonModel>.from(_salons);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slight gray background

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pet Salon',
          style: TextStyle(
            color: Color(0xFF3293B3),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF2C3E50)),
            onPressed: () async {
              final result = await showSalonFilterSheet(context);

              if (result != null && result is Map) {
                setState(() {
                  _filterLocation = result['location'] as String?;
                  _filterConcern = result['concern'] as String?;
                  _filterSpecies = result['species'] as String?;
                  _filterDates = List<String>.from(result['dates'] ?? []);
                });

                _fetchSalons(
                  location: _filterLocation,
                  concern: _filterConcern,
                  species: _filterSpecies,
                  dates: _filterDates,
                );
              }
            },
          ),
        ],
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
          children: [
            if (filteredSalons.isEmpty)
              const Center(child: Text("No salons found. Check back later!"))
            else
              ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: filteredSalons.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return SalonCard(salon: filteredSalons[index]);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2), // Adjust if needed
    );
  }
}

class SalonCard extends StatelessWidget {
  final SalonModel salon;

  const SalonCard({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon / Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: salon.profilePictureUrl == null || salon.profilePictureUrl!.isEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFF7A94FF), Color(0xFF3B5BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: salon.profilePictureUrl != null && salon.profilePictureUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(salon.profilePictureUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: salon.profilePictureUrl == null || salon.profilePictureUrl!.isEmpty
                    ? const Icon(Icons.content_cut, color: Colors.white, size: 30)
                    : null,
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: ${salon.ownerName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
          ),
          
          // Stats Row
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 6),
              Text(
                salon.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(width: 24),
              
              const Icon(Icons.calendar_today_outlined, color: Colors.black54, size: 18),
              const SizedBox(width: 6),
              Text(
                '${salon.totalBookings} bookings',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
          ),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalonProfilePage(salon: salon),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2E8F0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalonBookingPage(salon: salon),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}