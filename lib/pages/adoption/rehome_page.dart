import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
              onTap: () {
                // Trigger image picker logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image upload tapped')),
                );
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF3293B3)),
                ),
                child: Column(
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
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Pet type', 'Write your pet type here', (v) => petType = v),
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  // Submit API call here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pet submitted for re-homing!')),
                  );
                }
              },
              child: Text(
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
