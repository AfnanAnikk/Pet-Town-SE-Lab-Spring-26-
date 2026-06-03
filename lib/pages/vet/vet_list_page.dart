import 'package:flutter/material.dart';
import '../../models/vet_model.dart';
import '../../services/api_service.dart';
import '../../widgets/vet_filter_sheet.dart';
import 'vet_profile_page.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class VetListPage extends StatefulWidget {
  const VetListPage({super.key});

  @override
  State<VetListPage> createState() => _VetListPageState();
}

class _VetListPageState extends State<VetListPage> {
  
  String? _filterLocation;
  String? _filterConcern;
  String? _filterSpecies;
  List<String> _filterDates = [];

  bool _isLoading = true;
  List<VetModel> _vets = [];

  @override
  void initState() {
    super.initState();
    _fetchVets();
  }

  Future<void> _fetchVets({
    String? location,
    String? concern,
    String? species,
    List<String>? dates,
  }) async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getAllVets(
      location: location,
      concern: concern,
      species: species,
      dates: dates,
    );

    if (result['success']) {
      final List<dynamic> data = result['data'];
      setState(() {
        _vets = data.map((json) => VetModel.fromJson(json)).toList();
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
    var filteredVets = List<VetModel>.from(_vets);

    return Scaffold(
      backgroundColor: Colors.white,

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
          'Pet Vet',
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
              final result = await showVetFilterSheet(context);

              if (result != null && result is Map) {
                setState(() {
                  _filterLocation = result['location'] as String?;
                  _filterConcern = result['concern'] as String?;
                  _filterSpecies = result['species'] as String?;
                  _filterDates = List<String>.from(result['dates'] ?? []);
                });

                _fetchVets(
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
            if (filteredVets.isEmpty)
              const Center(child: Text("No vets found. Be the first to register!"))
            else
              ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: filteredVets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  return VetCard(vet: filteredVets[index]);
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}

class VetCard extends StatelessWidget {
  final VetModel vet;

  const VetCard({super.key, required this.vet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VetProfilePage(vet: vet),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F7FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6E4F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFE0E0E0),
                  backgroundImage: vet.profilePictureUrl != null && vet.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(vet.profilePictureUrl!)
                      : null,
                  child: vet.profilePictureUrl == null || vet.profilePictureUrl!.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vet.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3293B3),
                              ),
                            ),
                          ),

                          if (vet.isVerified)
                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 20,
                            ),

                          const SizedBox(width: 8),

                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black54,
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        vet.degree,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            vet.location,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${vet.rating} • ${vet.reviewCount} Reviews',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vet.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD6E4F0)),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5C88A8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            ...vet.availableSlots.take(2).map((slot) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: slot.split(' at ')[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: ' at ${slot.split(' at ')[1]}'),
                        ],
                      ),
                    ),

                    Text(
                      'BDT ${vet.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }),

            if (vet.availableSlots.length > 2)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'See more timeslots',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5C88A8),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}