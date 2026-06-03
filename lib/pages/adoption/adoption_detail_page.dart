import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdoptionDetailPage extends StatelessWidget {
  final Map<String, dynamic> adoption;

  const AdoptionDetailPage({super.key, required this.adoption});

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
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  adoption['image_url'] ?? 'https://via.placeholder.com/400x300',
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      adoption['pet_name'] ?? 'Unknown',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: const Color(0xFF3293B3), offset: const Offset(1, 1), blurRadius: 4),
                          Shadow(color: const Color(0xFF3293B3), offset: const Offset(-1, -1), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -25),
              child: Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3293B3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      // Request booking action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking request sent!')),
                      );
                    },
                    child: Text(
                      'Check Booking',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Profile', adoption['pet_age'] ?? 'Unknown'),
                    _buildInfoRow(adoption['pet_type'] ?? 'Type', adoption['pet_breed'] ?? 'Unknown'),
                    _buildInfoRow('Traits', adoption['pet_traits'] ?? 'Unknown'),
                    _buildInfoRow('Gender', adoption['pet_gender'] ?? 'Unknown'),
                    _buildInfoRow('Food Habit', adoption['pet_food_habit'] ?? 'Unknown'),
                    _buildInfoRow('Contact No', adoption['owner_contact'] ?? 'Unknown'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                adoption['description'] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
