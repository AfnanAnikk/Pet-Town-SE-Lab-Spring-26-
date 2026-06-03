import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class SalonProviderProfilePage extends StatefulWidget {
  const SalonProviderProfilePage({super.key});

  @override
  State<SalonProviderProfilePage> createState() => _SalonProviderProfilePageState();
}

class _SalonProviderProfilePageState extends State<SalonProviderProfilePage> {
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  final TextEditingController _nameController = TextEditingController(); // Salon Name
  final TextEditingController _ownerNameController = TextEditingController(); // Owner Name
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _feeController = TextEditingController(); // Base Price
  final TextEditingController _aboutController = TextEditingController();
  
  final List<String> _predefinedTags = [
    'Grooming', 'Styling', 'Spa', 'Nail Care', 'Massage',
    'Teeth Cleaning', 'Flea Treatment', 'Boarding'
  ];
  List<String> _selectedTags = [];
  
  List<DateTime> _timeslots = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final res = await ApiService.getSalonProfile(userId.toString());
      if (res['success'] && res['data'] != null) {
        final data = res['data'];
        setState(() {
          _nameController.text = data['name'] ?? '';
          _ownerNameController.text = data['owner_name'] ?? '';
          _locationController.text = data['location'] ?? '';
          _feeController.text = data['price']?.toString() ?? '0';
          _aboutController.text = data['profile_description'] ?? '';
          _profileImageUrl = data['profile_picture_url'];
          
          _selectedTags = List<String>.from(data['tags'] ?? []);
          
          // Parse timeslots back to DateTime objects for internal representation
          _timeslots = [];
          if (data['availableSlots'] != null) {
             for (String slot in data['availableSlots']) {
                try {
                  final parts = slot.split(' at ');
                  if (parts.length == 2) {
                    final dateParts = parts[0].split('/');
                    final timeParts = parts[1].split(' ');
                    final timeNumParts = timeParts[0].split(':');
                    
                    int day = int.parse(dateParts[0]);
                    int month = int.parse(dateParts[1]);
                    int year = int.parse(dateParts[2]);
                    
                    int hour = int.parse(timeNumParts[0]);
                    int minute = int.parse(timeNumParts[1]);
                    if (timeParts[1].toLowerCase() == 'pm' && hour < 12) hour += 12;
                    if (timeParts[1].toLowerCase() == 'am' && hour == 12) hour = 0;
                    
                    _timeslots.add(DateTime(year, month, day, hour, minute));
                  }
                } catch (e) {
                  // Ignore parsing errors for individual slots
                }
             }
          }
        });
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _locationController.dispose();
    _feeController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salon Profile Settings',
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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(16),
                    image: _profileImage != null
                        ? DecorationImage(image: FileImage(_profileImage!), fit: BoxFit.cover)
                        : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                            : null),
                  ),
                  child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                      ? const Icon(Icons.store, size: 60, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
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
          _buildTextField('Salon Name', _nameController),
          _buildTextField('Owner Name', _ownerNameController),
          _buildTextField('Location / Address', _locationController),
          _buildTextField('Base Price (BDT)', _feeController, isNumber: true),
          _buildTextField('About Salon', _aboutController, maxLines: 4),
          
          const SizedBox(height: 24),
          
          // Tags
          _buildSectionHeader('Services & Amenities (Tags)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
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
              return _predefinedTags.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase()) && 
                       !_selectedTags.contains(option);
              });
            },
            onSelected: (String selection) {
              setState(() {
                if (!_selectedTags.contains(selection)) {
                  _selectedTags.add(selection);
                }
              });
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Type a tag (e.g., Grooming)',
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
                          if (!_selectedTags.contains(textEditingController.text)) {
                            _selectedTags.add(textEditingController.text);
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
                      if (!_selectedTags.contains(value)) {
                        _selectedTags.add(value);
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
          
          // Timeslots
          _buildSectionHeader('Available Slots'),
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
            title: const Text('Add Slot', style: TextStyle(color: Color(0xFF3FA9F5))),
            leading: const Icon(Icons.add_circle_outline, color: Color(0xFF3FA9F5)),
            onTap: _showAddSlotPicker,
          ),
          
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final userId = await AuthService.getUserId();
                if (userId == null) return;

                setState(() => _isLoading = true);

                String? uploadedUrl = _profileImageUrl;
                if (_profileImage != null) {
                  final uploadRes = await ApiService.uploadImage(_profileImage!.path);
                  if (uploadRes['success']) {
                    uploadedUrl = uploadRes['data']['url'];
                    setState(() {
                      _profileImageUrl = uploadedUrl;
                    });
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(uploadRes['message'] ?? 'Image upload failed')),
                      );
                    }
                    return;
                  }
                }
                
                final payload = {
                  'userId': userId.toString(),
                  'name': _nameController.text,
                  'ownerName': _ownerNameController.text,
                  'location': _locationController.text,
                  'price': int.tryParse(_feeController.text) ?? 0,
                  'profileDescription': _aboutController.text,
                  'tags': _selectedTags,
                  'profilePictureUrl': uploadedUrl,
                  'availableSlots': _timeslots.map((slot) {
                    final timeStr = TimeOfDay.fromDateTime(slot).format(context);
                    final dateStr = '${slot.day}/${slot.month}/${slot.year}';
                    return '$dateStr at $timeStr';
                  }).toList(),
                };
                
                final res = await ApiService.updateSalonProfile(payload);
                setState(() => _isLoading = false);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['data']?['message'] ?? res['message'] ?? 'Salon profile updated successfully!')),
                  );
                }
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
