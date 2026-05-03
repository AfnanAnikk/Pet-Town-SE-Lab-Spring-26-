import 'package:flutter/material.dart';
import '../../models/vet_model.dart';
import '../../services/api_service.dart';
import '../../widgets/vet_filter_sheet.dart';
import 'vet_profile_page.dart';

class VetListPage extends StatefulWidget {
  const VetListPage({super.key});

  @override
  State<VetListPage> createState() => _VetListPageState();
}

class _VetListPageState extends State<VetListPage> {
  bool _showFeatureMenu = false;
  int _selectedIndex = 2; //
  
  String? _filterLocation;
  String? _filterConcern;
  String? _filterSpecies;

  bool _isLoading = true;
  List<VetModel> _vets = [];

  @override
  void initState() {
    super.initState();
    _fetchVets();
  }

  Future<void> _fetchVets({String? location, String? concern, String? species}) async {
    setState(() {
      _isLoading = true;
    });
    final result = await ApiService.getAllVets(location: location, concern: concern, species: species);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
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
              if (result != null && result is Map<String, String?>) {
                setState(() {
                  _filterLocation = result['location'];
                  _filterConcern = result['concern'];
                  _filterSpecies = result['species'];
                });
                _fetchVets(location: _filterLocation, concern: _filterConcern, species: _filterSpecies);
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

            if (_showFeatureMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFeatureMenu = false;
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

            if (_showFeatureMenu)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
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
                            icon: Image.asset(
                              'assets/images/vet1.png',
                              width: 28,
                            ),
                            tooltip: 'Pet Vet',
                            onTap: () {
                              setState(() {
                                _showFeatureMenu = false;
                              });
                            },
                          ),

                          _buildFeatureIcon(
                            icon: Image.asset(
                              'assets/images/marketplace.png',
                              width: 28,
                            ),
                            tooltip: 'Marketplace',
                            onTap: () {
                              setState(() {
                                _showFeatureMenu = false;
                              });
                            },
                          ),

                          _buildFeatureIcon(
                            icon: Image.asset(
                              'assets/images/adoption.png',
                              width: 28,
                            ),
                            tooltip: 'Adoption',
                            onTap: () {
                              setState(() {
                                _showFeatureMenu = false;
                              });
                            },
                          ),

                          _buildFeatureIcon(
                            icon: Image.asset(
                              'assets/images/events.png',
                              width: 28,
                            ),
                            tooltip: 'Events',
                            onTap: () {
                              setState(() {
                                _showFeatureMenu = false;
                              });
                            },
                          ),

                          _buildFeatureIcon(
                            icon: Image.asset(
                              'assets/images/grooming.png',
                              width: 28,
                            ),
                            tooltip: 'Grooming',
                            onTap: () {
                              setState(() {
                                _showFeatureMenu = false;
                              });
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
          if (index == 0) {
            Navigator.pop(context);
            return;
          }

          if (index == 2) {
            setState(() {
              _showFeatureMenu = !_showFeatureMenu;
              _selectedIndex = 2;
            });
          } else {
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
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
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