import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'new_friend_page.dart';

class RehomePage extends StatefulWidget {
  final VoidCallback onSubmitted;

  const RehomePage({
    super.key,
    required this.onSubmitted,
  });

  @override
  State<RehomePage> createState() => RehomePageState();
}

class RehomePageState extends State<RehomePage> {
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

  File? imageFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitAdoption() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image of the pet.')),
      );
      return;
    }

    _formKey.currentState!.save();

    final userId = await AuthService.getUserId();

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    String accountUsername = 'User';

    final profileRes = await AuthService.getProfile(userId);
    if (profileRes['success'] == true && profileRes['data'] != null) {
      final user = profileRes['data']['user'] ?? profileRes['data'];
      accountUsername = user['username'] ?? user['display_name'] ?? 'User';
    }

    setState(() => _isSubmitting = true);

    // 1. Upload image to Cloudinary via backend
    String imageUrl = '';
    final uploadRes = await ApiService.uploadImage(imageFile!.path);
    
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
      'pet_name': petType?.trim().isNotEmpty == true ? petType!.trim() : '',
      'pet_type': petType, 
      'pet_age': petAge,
      'pet_breed': petBreed,
      'pet_traits': petTraits,
      'pet_gender': petGender,
      'pet_food_habit': petFoodHabit,
      'owner_name': '$accountUsername (${ownerName?.trim() ?? ''})',
      'owner_contact': ownerContact,
      'description': description,
      'image_url': imageUrl
    });

    setState(() => _isSubmitting = false);

    if (postRes['success']) {
      if (mounted) {
        _formKey.currentState!.reset();

        setState(() {
          imageFile = null;
        });

        widget.onSubmitted();
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1F1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF3293B3).withValues(alpha: 0.35),
                    ),
                    image: imageFile != null
                        ? DecorationImage(
                            image: FileImage(imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3293B3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Choose pet photo',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF374957),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload a clear image for adoption',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Change photo',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Pet name / type', 'Write your pet name here', (v) => petType = v),
            _buildTextField('Pet Profile', 'Write your pet age here', (v) => petAge = v),
            _buildTextField('Pet Breed', 'Write your pet breed here', (v) => petBreed = v),
            _buildTextField('Pet Traits', 'Write your pet traits here', (v) => petTraits = v),
            _buildTextField('Pet Gender', 'Write your pet gender here', (v) => petGender = v),
            _buildTextField('Pet Food Habit', 'Write your pet food habit here', (v) => petFoodHabit = v),
            _buildTextField('Nickname', 'Write your name here', (v) => ownerName = v),
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
                      'Post',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    Function(String?) onSaved, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374957),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor: const Color(0xFFEAF1F1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF3293B3),
                  width: 1.4,
                ),
              ),
            ),
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required field' : null,
            onSaved: onSaved,
          ),
        ],
      ),
    );
  }
}
