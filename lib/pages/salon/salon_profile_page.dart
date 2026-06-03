import 'package:flutter/material.dart';
import '../../models/salon_model.dart';
import 'salon_booking_page.dart';

class SalonProfilePage extends StatefulWidget {
  final SalonModel salon;

  const SalonProfilePage({super.key, required this.salon});

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  String? selectedSlot;

  @override
  void initState() {
    super.initState();
    selectedSlot = null;
  }

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
                      ? const Icon(Icons.content_cut, color: Colors.white, size: 40)
                      : null,
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
                              salon.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3293B3),
                              ),
                            ),
                          ),
                          if (salon.isVerified)
                            const Icon(Icons.verified, color: Colors.green, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${salon.ownerName}',
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            salon.location,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${salon.rating.toStringAsFixed(1)} • ${salon.reviewCount} Reviews',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${salon.totalBookings}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tags (Services)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: salon.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD6E4F0)),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5C88A8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              salon.profileDescription.isEmpty ? "No description provided." : salon.profileDescription,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
            ),
            const SizedBox(height: 8),
            
            const Divider(height: 48, color: Colors.grey),
            
            // Reviews Header
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${salon.rating.toStringAsFixed(1)} • ${salon.reviewCount} Reviews',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reviews List
            if (salon.reviews.isEmpty)
              const Text("No reviews yet.", style: TextStyle(color: Colors.black54))
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: salon.reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final review = salon.reviews[index];
                    return Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              review.text,
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  review.authorInitial,
                                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review.authorName,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      review.date,
                                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            const Divider(height: 48, color: Colors.grey),
            
            // Book Appointment times
            const Text('Book Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (salon.availableSlots.isEmpty)
              const Text("No available slots right now.", style: TextStyle(color: Colors.black54))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: salon.availableSlots.map((slot) {
                    final isSelected = slot == selectedSlot;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedSlot = slot;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF3FA9F5) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              slot.split(' at ')[0],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF3FA9F5) : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (slot.contains(' at '))
                              Text(
                                slot.split(' at ')[1],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? const Color(0xFF3FA9F5) : Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      // Fixed Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BDT ${salon.price}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(
                      'Base price',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonBookingPage(
                        salon: salon,
                        selectedSlot: selectedSlot,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3FA9F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
