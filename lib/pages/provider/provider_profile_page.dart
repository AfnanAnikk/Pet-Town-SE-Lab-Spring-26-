import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProviderProfilePage extends StatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Mock initial data
  final TextEditingController _nameController = TextEditingController(text: 'Dr. Afnan Mehmud');
  final TextEditingController _degreeController = TextEditingController(text: 'DVM, MS in Veterinary Surgery');
  final TextEditingController _locationController = TextEditingController(text: 'Dhaka, Bangladesh');
  final TextEditingController _feeController = TextEditingController(text: '800');
  final TextEditingController _aboutController = TextEditingController(
      text: 'Passionate veterinarian with over 10 years of experience in small animal surgery and preventive care.');
  
  final List<String> _predefinedSkills = [
    'Immunologist', 'Vaccinologist', 'Biosecurity Veterinarian',
    'Dermatologist', 'Surgeon', 'Dentist', 'Cardiologist',
    'Nutritionist', 'Behaviorist', 'Neurologist', 'Oncologist', 'Ophthalmologist'
  ];
  final List<String> _selectedSkills = ['Surgeon'];
  
  final List<String> _speciesTreated = ['Dog', 'Cat'];
  final List<String> _availableSpecies = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Reptile', 'Equine'];

  final List<String> _areasOfInterest = ['Dermatology', 'Surgery'];
  final TextEditingController _newAreaController = TextEditingController();

  final List<DateTime> _timeslots = [
    DateTime.now().add(const Duration(hours: 2)),
    DateTime.now().add(const Duration(days: 1, hours: 2)),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _degreeController.dispose();
    _locationController.dispose();
    _feeController.dispose();
    _aboutController.dispose();
    _newAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374957),
            ),
          ),
          const SizedBox(height: 24),
          
          // Profile Picture
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFE0E0E0),
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3FA9F5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Basic Info Section
          _buildSectionHeader('Basic Information'),
          _buildTextField('Full Name', _nameController),
          _buildTextField('Professional Title / Degree', _degreeController),
          _buildTextField('Location / Clinic Address', _locationController),
          _buildTextField('Consultation Fee (BDT)', _feeController, isNumber: true),
          _buildTextField('About You', _aboutController, maxLines: 4),
          
          const SizedBox(height: 24),
          
          // Area of Expertise (LinkedIn style)
          _buildSectionHeader('Area of Expertise'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedSkills.map((skill) {
              return Chip(
                label: Text(skill),
                onDeleted: () {
                  setState(() {
                    _selectedSkills.remove(skill);
                  });
                },
                backgroundColor: const Color(0xFFE8F5E9),
                side: BorderSide(color: Colors.green.shade200),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _predefinedSkills.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase()) && 
                       !_selectedSkills.contains(option);
              });
            },
            onSelected: (String selection) {
              setState(() {
                if (!_selectedSkills.contains(selection)) {
                  _selectedSkills.add(selection);
                }
              });
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a skill (e.g., Vaccinologist)',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3FA9F5)),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF3FA9F5)),
                    onPressed: () {
                      if (textEditingController.text.isNotEmpty) {
                        setState(() {
                          if (!_selectedSkills.contains(textEditingController.text)) {
                            _selectedSkills.add(textEditingController.text);
                          }
                          textEditingController.clear();
                        });
                      }
                    },
                  ),
                ),
                onSubmitted: (String value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      if (!_selectedSkills.contains(value)) {
                        _selectedSkills.add(value);
                      }
                      textEditingController.clear();
                    });
                  }
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            onSelected(option);
                            // Clears the field automatically via Autocomplete behavior
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Species Treated
          _buildSectionHeader('Species Treated'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSpecies.map((species) {
              final isSelected = _speciesTreated.contains(species);
              return FilterChip(
                label: Text(species),
                selected: isSelected,
                selectedColor: const Color(0xFF3FA9F5).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF3FA9F5),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      _speciesTreated.add(species);
                    } else {
                      _speciesTreated.remove(species);
                    }
                  });
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Areas of Interest
          _buildSectionHeader('Areas of Interest'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._areasOfInterest.map((area) => Chip(
                    label: Text(area),
                    onDeleted: () {
                      setState(() {
                        _areasOfInterest.remove(area);
                      });
                    },
                  )),
              ActionChip(
                label: const Text('+ Add New'),
                onPressed: _showAddAreaDialog,
                backgroundColor: Colors.grey.shade100,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Timeslots
          _buildSectionHeader('Available Timeslots'),
          ..._timeslots.map((slot) {
            final timeStr = TimeOfDay.fromDateTime(slot).format(context);
            final dateStr = '${slot.day}/${slot.month}/${slot.year}';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('$dateStr at $timeStr'),
              leading: const Icon(Icons.access_time, color: Color(0xFF3FA9F5)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _timeslots.remove(slot);
                  });
                },
              ),
            );
          }),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add Timeslot', style: TextStyle(color: Color(0xFF3FA9F5))),
            leading: const Icon(Icons.add_circle_outline, color: Color(0xFF3FA9F5)),
            onTap: _showAddSlotPicker,
          ),
          
          const SizedBox(height: 40),
          
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3FA9F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3293B3),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3FA9F5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAreaDialog() {
    _newAreaController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Area of Interest'),
        content: TextField(
          controller: _newAreaController,
          decoration: const InputDecoration(hintText: 'e.g. Neurology'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_newAreaController.text.isNotEmpty) {
                setState(() {
                  _areasOfInterest.add(_newAreaController.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSlotPicker() async {
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
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

      if (pickedTime != null) {
        setState(() {
          _timeslots.add(DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
          // Sort timeslots chronologically
          _timeslots.sort((a, b) => a.compareTo(b));
        });
      }
    }
  }
}
