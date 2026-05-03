import 'package:flutter/material.dart';

class VetFilterSheet extends StatefulWidget {
  const VetFilterSheet({super.key});

  @override
  State<VetFilterSheet> createState() => _VetFilterSheetState();
}

class _VetFilterSheetState extends State<VetFilterSheet> {
  String _selectedSpecies = 'Dog';
  String? _selectedConcern;
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Widget _buildDateBox(String title, String subtitle, {bool isSelected = false, bool isNextAvailable = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF3293B3) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isNextAvailable)
            Text(
              'Next\navailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF3293B3) : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          else ...[
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBox(String title, IconData icon, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF3293B3) : Colors.grey.shade400,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),

      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    const Text(
                      'Your location',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'City (e.g. Dhaka, Chittagong)',
                        prefixIcon: const Icon(Icons.location_on, color: Colors.black54),
                        suffixIcon: const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date
                    const Text(
                      'Choose a date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildDateBox('', '', isSelected: true, isNextAvailable: true),
                          _buildDateBox('Today', '9'),
                          _buildDateBox('Tomorrow', '10'),
                          _buildDateBox('Sun', '11'),
                          _buildDateBox('Monday', '12'),
                          _buildDateBox('Tuesday', '13'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                        SizedBox(width: 8),
                        Text('Next available', style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Species
                    const Text(
                      'Species',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBox(
                      'Dog', 
                      Icons.pets, 
                      isSelected: _selectedSpecies == 'Dog',
                      onTap: () => setState(() => _selectedSpecies = 'Dog'),
                    ),
                    _buildCategoryBox(
                      'Cat', 
                      Icons.pets_sharp,
                      isSelected: _selectedSpecies == 'Cat',
                      onTap: () => setState(() => _selectedSpecies = 'Cat'),
                    ),
                    _buildCategoryBox(
                      'Bird', 
                      Icons.flutter_dash, 
                      isSelected: _selectedSpecies == 'Bird',
                      onTap: () => setState(() => _selectedSpecies = 'Bird'),
                    ),
                    const SizedBox(height: 12),
                    
                    // Other Categories
                    const Text(
                      'Concern',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBox(
                      'Vaccines & Preventive care', Icons.vaccines,
                      isSelected: _selectedConcern == 'Vaccines & Preventive care',
                      onTap: () => setState(() => _selectedConcern = 'Vaccines & Preventive care'),
                    ),
                    _buildCategoryBox(
                      'Injury & Infection', Icons.healing,
                      isSelected: _selectedConcern == 'Injury & Infection',
                      onTap: () => setState(() => _selectedConcern = 'Injury & Infection'),
                    ),
                    _buildCategoryBox(
                      'Cancer & Chronic Care', Icons.medical_services_outlined,
                      isSelected: _selectedConcern == 'Cancer & Chronic Care',
                      onTap: () => setState(() => _selectedConcern = 'Cancer & Chronic Care'),
                    ),
                    _buildCategoryBox(
                      'Wellness & Checkups', Icons.monitor_heart_outlined,
                      isSelected: _selectedConcern == 'Wellness & Checkups',
                      onTap: () => setState(() => _selectedConcern = 'Wellness & Checkups'),
                    ),
                    _buildCategoryBox(
                      'Skin & Allergies', Icons.back_hand_outlined,
                      isSelected: _selectedConcern == 'Skin & Allergies',
                      onTap: () => setState(() => _selectedConcern = 'Skin & Allergies'),
                    ),
                    _buildCategoryBox(
                      'Dental Care', Icons.medical_information_outlined,
                      isSelected: _selectedConcern == 'Dental Care',
                      onTap: () => setState(() => _selectedConcern = 'Dental Care'),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Pinned Bottom Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'location': null,
                          'concern': null,
                          'species': null,
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'location': _locationController.text.isNotEmpty ? _locationController.text : null,
                          'concern': _selectedConcern,
                          'species': _selectedSpecies,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3FA9F5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

Future<dynamic> showVetFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const VetFilterSheet(),
  );
}
