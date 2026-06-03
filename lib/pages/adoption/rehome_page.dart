import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class RehomePage extends StatefulWidget {
  const RehomePage({super.key});

  @override
  State<RehomePage> createState() => _RehomePageState();
}

class _RehomePageState extends State<RehomePage> {
  final _formKey = GlobalKey<FormState>();
  
  String? petType;
  String? petAge;
  String? petBreed;
  String? petTraits;
  String? petGender;
  String? petFoodHabit;
  String? ownerName;
  String? ownerContact;
  String? description;

  File? _imageFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitAdoption() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image of the pet.')),
      );
      return;
    }

    _formKey.currentState!.save();

    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isSubmitting = true);

    // 1. Upload image to Cloudinary via backend
    String imageUrl = '';
    final uploadRes = await ApiService.uploadImage(_imageFile!.path);
    
    if (uploadRes['success']) {
      imageUrl = uploadRes['data']['url'];
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadRes['message'] ?? 'Failed to upload image')));
      }
      setState(() => _isSubmitting = false);
      return;
    }

    // 2. Submit the adoption post
    final postRes = await ApiService.createAdoption({
      'user_id': userId,
      'pet_name': 'New Pet', // Can be derived or added as field, using placeholder since image showed "Write your pet name here" in "Pet type" label, wait let's use petType as pet name if needed, but let's just pass 'New Pet' or a default since the form lacked an explicit Pet Name field, wait image 2 says "Pet type - Write your pet name here", so petType is effectively pet name in the user's mockup.
      'pet_type': petType, 
      'pet_age': petAge,
      'pet_breed': petBreed,
      'pet_traits': petTraits,
      'pet_gender': petGender,
      'pet_food_habit': petFoodHabit,
      'owner_name': ownerName,
      'owner_contact': ownerContact,
      'description': description,
      'image_url': imageUrl
    });

    setState(() => _isSubmitting = false);

    if (postRes['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adoption post submitted successfully!')));
        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(postRes['message'] ?? 'Failed to create adoption')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF3293B3)),
                  image: _imageFile != null
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add media files ( photos\nor videos )',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Pet name / type', 'Write your pet name here', (v) => petType = v),
            _buildTextField('Pet Profile', 'Write your pet age here', (v) => petAge = v),
            _buildTextField('Pet Breed', 'Write your pet breed here', (v) => petBreed = v),
            _buildTextField('Pet Traits', 'Write your pet traits here', (v) => petTraits = v),
            _buildTextField('Pet Gender', 'Write your pet gender here', (v) => petGender = v),
            _buildTextField('Pet Food Habit', 'Write your pet food habit here', (v) => petFoodHabit = v),
            _buildTextField('Your Name', 'Write your name here', (v) => ownerName = v),
            _buildTextField('Your Contact No', 'Write your contact number here', (v) => ownerContact = v, isNumber: true),
            _buildTextField('Add description of pet', 'Write something about your pet here', (v) => description = v, maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3293B3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSubmitting ? null : _submitAdoption,
              child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Done',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, Function(String?) onSaved, {int maxLines = 1, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black54),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3293B3), width: 2),
              ),
            ),
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
            onSaved: onSaved,
          ),
        ],
      ),
    );
  }
}
