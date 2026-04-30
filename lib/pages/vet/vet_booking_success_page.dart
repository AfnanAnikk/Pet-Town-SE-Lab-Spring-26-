import 'package:flutter/material.dart';
import '../../models/vet_model.dart';
import '../home/home_page.dart';

class VetBookingSuccessPage extends StatelessWidget {
  final VetModel vet;
  final String dateStr;
  final String timeStr;
  final String reason;

  const VetBookingSuccessPage({
    super.key,
    required this.vet,
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
          'Pet Vet',
          style: TextStyle(
            color: Color(0xFF3FA9F5),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, color: Colors.grey),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  'Booking Confirmed ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3293B3),
                  ),
                ),
                Icon(Icons.check, color: Colors.green, size: 28),
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
                  // Top section with Vet Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    vet.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3293B3),
                                    ),
                                  ),
                                ),
                                if (vet.isVerified)
                                  const Icon(Icons.verified, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: Colors.black87),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vet.degree,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${vet.rating} • ${vet.reviewCount} Reviews',
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
                    children: vet.tags.map((tag) {
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
                    'Reason for visit: $reason',
                    style: const TextStyle(fontSize: 14, color: Color(0xFFFF7A7A)), // Reddish text
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Rate Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Rate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            'by Jan 29, 2026',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(5, (index) => const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.star_border, color: Colors.amber, size: 28),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar (Matching Home)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(255, 124, 124, 124),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/home.png', width: 28, height: 28, fit: BoxFit.contain),
            activeIcon: Image.asset('assets/images/home1.png', width: 28, height: 28, fit: BoxFit.contain),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 28),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/features.png', width: 28, height: 28, fit: BoxFit.contain),
            activeIcon: Image.asset('assets/images/features1.png', width: 28, height: 28, fit: BoxFit.contain),
            label: 'Features',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none, size: 28),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFE0E0E0),
                child: Icon(Icons.person, size: 16, color: Colors.grey),
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
