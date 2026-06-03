import 'package:flutter/material.dart';

class SalonFilterSheet extends StatefulWidget {
  const SalonFilterSheet({super.key});

  @override
  State<SalonFilterSheet> createState() => _SalonFilterSheetState();
}

class _SalonFilterSheetState extends State<SalonFilterSheet> {
  String _selectedSpecies = '';
  String? _selectedConcern;
  List<DateTime> _selectedDates = [];
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _showAddDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3FA9F5),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      setState(() {
        final alreadyExists = _selectedDates.any((date) =>
            date.day == pickedDate.day &&
            date.month == pickedDate.month &&
            date.year == pickedDate.year);

        if (!alreadyExists) {
          _selectedDates.add(pickedDate);
          _selectedDates.sort((a, b) => a.compareTo(b));
        }
      });
    }
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
                    const SizedBox(height: 12),
                    
                    // Date
                    const Text(
                      'Choose a date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      children: [
                        ..._selectedDates.map((date) {
                          final dateStr = '${date.day}/${date.month}/${date.year}';

                          return Chip(
                            label: Text(dateStr),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedDates.remove(date);
                              });
                            },
                            backgroundColor: const Color(0xFFEAF6FF),
                            side: BorderSide(color: Colors.blue.shade100),
                          );
                        }),

                        ActionChip(
                          label: const Text('+ Add Date'),
                          avatar: const Icon(Icons.calendar_today, size: 16),
                          onPressed: _showAddDatePicker,
                          backgroundColor: const Color.fromARGB(255, 255, 254, 254),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
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
                      'Service Required',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryBox(
                      'Grooming & Bath', Icons.bathtub_outlined,
                      isSelected: _selectedConcern == 'Grooming & Bath',
                      onTap: () => setState(() => _selectedConcern = 'Grooming & Bath'),
                    ),
                    _buildCategoryBox(
                      'Haircut & Styling', Icons.content_cut_outlined,
                      isSelected: _selectedConcern == 'Haircut & Styling',
                      onTap: () => setState(() => _selectedConcern = 'Haircut & Styling'),
                    ),
                    _buildCategoryBox(
                      'Nail Trimming', Icons.back_hand_outlined,
                      isSelected: _selectedConcern == 'Nail Trimming',
                      onTap: () => setState(() => _selectedConcern = 'Nail Trimming'),
                    ),
                    _buildCategoryBox(
                      'Spa & Massage', Icons.spa_outlined,
                      isSelected: _selectedConcern == 'Spa & Massage',
                      onTap: () => setState(() => _selectedConcern = 'Spa & Massage'),
                    ),
                    _buildCategoryBox(
                      'Flea & Tick Treatment', Icons.bug_report_outlined,
                      isSelected: _selectedConcern == 'Flea & Tick Treatment',
                      onTap: () => setState(() => _selectedConcern = 'Flea & Tick Treatment'),
                    ),
                    _buildCategoryBox(
                      'Teeth Cleaning', Icons.health_and_safety_outlined,
                      isSelected: _selectedConcern == 'Teeth Cleaning',
                      onTap: () => setState(() => _selectedConcern = 'Teeth Cleaning'),
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
                          'dates': [],
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
                          'dates': _selectedDates.map((date) => '${date.day}/${date.month}/${date.year}').toList(),
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

Future<dynamic> showSalonFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SalonFilterSheet(),
  );
}
