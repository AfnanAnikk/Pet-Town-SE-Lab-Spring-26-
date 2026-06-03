import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShelterDetailPage extends StatefulWidget {
  final Map<String, dynamic> shelter;

  const ShelterDetailPage({super.key, required this.shelter});

  @override
  State<ShelterDetailPage> createState() => _ShelterDetailPageState();
}

class _ShelterDetailPageState extends State<ShelterDetailPage> {
  final _formKey = GlobalKey<FormState>();
  
  String? petType;
  String? petName;
  String? fromDate;
  String? toDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Adoption',
          style: GoogleFonts.outfit(
            color: const Color(0xFF3293B3),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(widget.shelter['logo_url'] ?? 'https://via.placeholder.com/50'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shelter['name'] ?? 'NGO',
                      style: const TextStyle(
                        color: Color(0xFF3293B3),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.shelter['location'] ?? 'Location',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSeatInfo('Total Seat', widget.shelter['total_seat']?.toString() ?? '0'),
            const SizedBox(height: 12),
            _buildSeatInfo('Occupied Seat', widget.shelter['occupied_seat']?.toString() ?? '0'),
            const SizedBox(height: 12),
            _buildSeatInfo('Vacant Seat', widget.shelter['vacant_seat']?.toString() ?? '0'),
            const SizedBox(height: 40),
            Text(
              'Wanna Book for Shelter ?',
              style: GoogleFonts.outfit(
                color: const Color(0xFF3293B3),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildRoundedTextField('Pet type', (v) => petType = v),
                  const SizedBox(height: 16),
                  _buildRoundedTextField('Pet Name', (v) => petName = v),
                  const SizedBox(height: 16),
                  _buildRoundedTextField('From : dd/mm/yyyy', (v) => fromDate = v),
                  const SizedBox(height: 16),
                  _buildRoundedTextField('To : dd/mm/yyyy', (v) => toDate = v),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3293B3),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // Submit booking
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shelter booking submitted!')),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Submit',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildSeatInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF3293B3).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRoundedTextField(String hint, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: const Color(0xFF3293B3).withOpacity(0.8), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFF3293B3), width: 2),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      onSaved: onSaved,
    );
  }
}
