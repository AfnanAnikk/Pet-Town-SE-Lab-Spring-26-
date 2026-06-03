import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shelter_detail_page.dart';

class SheltersPage extends StatefulWidget {
  const SheltersPage({super.key});

  @override
  State<SheltersPage> createState() => _SheltersPageState();
}

class _SheltersPageState extends State<SheltersPage> {
  List<dynamic> _shelters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShelters();
  }

  Future<void> _fetchShelters() async {
    try {
      final response = await http.get(Uri.parse('https://pet-town-backend.onrender.com/api/shelters'));
      if (response.statusCode == 200) {
        setState(() {
          _shelters = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Below is a list of Nonprofits, charities and NGOs working on providing rescue and rehabilitation services for injured or incarcerated animals. These NGOs often have expert veterinarians on their teams that perform surgeries on rescued animals. . Total Results = ${_shelters.length}",
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3293B3)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _shelters.length,
                itemBuilder: (context, index) {
                  final shelter = _shelters[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShelterDetailPage(shelter: shelter),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFF3293B3).withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(shelter['logo_url'] ?? 'https://via.placeholder.com/50'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shelter['name'] ?? 'Unknown NGO',
                                  style: const TextStyle(
                                    color: Color(0xFF3293B3),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.black54),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        shelter['location'] ?? 'Location not specified',
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: const [
                              Icon(Icons.facebook, color: Colors.blue, size: 24),
                              SizedBox(width: 8),
                              Icon(Icons.language, color: Colors.black54, size: 24),
                              SizedBox(width: 8),
                              Icon(Icons.favorite, color: Colors.black, size: 24),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}
