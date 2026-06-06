import 'package:flutter/material.dart';
import '../../models/salon_model.dart';
import '../home/home_page.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class SalonBookingSuccessPage extends StatelessWidget {
  final SalonModel salon;
  final String dateStr;
  final String timeStr;
  final String reason;

  const SalonBookingSuccessPage({
    super.key,
    required this.salon,
    required this.dateStr,
    required this.timeStr,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pet Salon',
          style: TextStyle(
            color: Color(0xFF3FA9F5),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  'Booking Placed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3293B3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Premium Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1F8), // Light blue background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top section with Salon Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: salon.profilePictureUrl == null || salon.profilePictureUrl!.isEmpty
                              ? const LinearGradient(
                                  colors: [Color(0xFF7A94FF), Color(0xFF3B5BFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          image: salon.profilePictureUrl != null && salon.profilePictureUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(salon.profilePictureUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: salon.profilePictureUrl == null || salon.profilePictureUrl!.isEmpty
                            ? const Icon(Icons.content_cut, color: Colors.white, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    salon.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3293B3),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (salon.isVerified)
                                  const Icon(Icons.verified, color: Colors.green, size: 20),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Owner: ${salon.ownerName}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${salon.rating.toStringAsFixed(1)} • ${salon.reviewCount} Reviews',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: salon.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF3293B3).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF5C88A8)),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white, thickness: 1.5),
                  ),
                  
                  // Appointment Details
                  Text(
                    'Time of visit: $dateStr at $timeStr',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instructions: $reason',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFFF7A7A)), // Reddish text
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rate Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Once Your Booking Is Confirmed',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            'Rate By ${DateFormat('dd/MM/yyyy').format(DateFormat('dd/MM/yyyy').parse(dateStr).add(const Duration(days: 7)))}',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3FA9F5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Color(0xFF3FA9F5), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}
