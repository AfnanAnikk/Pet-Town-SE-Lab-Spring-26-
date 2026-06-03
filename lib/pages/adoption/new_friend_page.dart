import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'adoption_detail_page.dart';

class NewFriendPage extends StatefulWidget {
  const NewFriendPage({super.key});

  @override
  State<NewFriendPage> createState() => _NewFriendPageState();
}

class _NewFriendPageState extends State<NewFriendPage> {
  List<dynamic> _adoptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdoptions();
  }

  Future<void> _fetchAdoptions() async {
    try {
      final response = await http.get(Uri.parse('https://pet-town-backend.onrender.com/api/adoptions'));
      if (response.statusCode == 200) {
        setState(() {
          _adoptions = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        // Fallback for local testing or handled error
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3293B3)));
    }

    if (_adoptions.isEmpty) {
      return const Center(child: Text("No pets available for adoption right now."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _adoptions.length,
      itemBuilder: (context, index) {
        final adoption = _adoptions[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdoptionDetailPage(adoption: adoption),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        adoption['image_url'] ?? 'https://via.placeholder.com/400x300',
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          adoption['pet_name'] ?? 'Unknown',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: const Color(0xFF3293B3), offset: const Offset(1, 1), blurRadius: 3),
                              Shadow(color: const Color(0xFF3293B3), offset: const Offset(-1, -1), blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text("For Adoption  ||  ${adoption['owner_contact'] ?? 'Unknown Location'}"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.pets, size: 18),
                          const SizedBox(width: 8),
                          Text("${adoption['pet_age'] ?? ''}  ||  ${adoption['pet_breed'] ?? ''}"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18),
                          const SizedBox(width: 8),
                          Text("${adoption['owner_name'] ?? 'Anonymous'}"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
