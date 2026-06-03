import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../messaging/chat_page.dart';
import '../../services/auth_service.dart';

class AdoptionDetailPage extends StatelessWidget {
  final Map<String, dynamic> adoption;

  const AdoptionDetailPage({super.key, required this.adoption});

  
  Future<void> _textOwner(BuildContext context) async {
    final currentUserId = await AuthService.getUserId();
    final ownerUserId = int.tryParse(adoption['user_id'].toString());

    if (ownerUserId == null) return;

    if (currentUserId == ownerUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: ownerUserId,
          otherUserName: adoption['username'] ?? adoption['owner_name'] ?? 'User',
          otherUserImage: adoption['profile_picture_url']?.toString() ?? '',
        ),
      ),
    );
  }
  void _showBookingSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    DateTime? pickupDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF3293B3),
                        onPrimary: Colors.white,
                        onSurface: Colors.black87,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setSheetState(() {
                  pickupDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Adoption Request',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF374957),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Send your pickup details for ${adoption['pet_name'] ?? 'this pet'}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _bookingField('Your Name', 'Enter your full name', nameController),
                    _bookingField('Phone Number', 'Enter your phone number', phoneController, keyboardType: TextInputType.phone),
                    _bookingField('Address', 'Enter pickup/address details', addressController, maxLines: 3),

                    Text(
                      'Pick-up Date',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF374957),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF3293B3)),
                            const SizedBox(width: 10),
                            Text(
                              pickupDate == null
                                  ? 'Choose pickup date'
                                  : '${pickupDate!.year}-${pickupDate!.month.toString().padLeft(2, '0')}-${pickupDate!.day.toString().padLeft(2, '0')}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: pickupDate == null ? Colors.grey.shade500 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty ||
                              phoneController.text.trim().isEmpty ||
                              addressController.text.trim().isEmpty ||
                              pickupDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all booking details')),
                            );
                            return;
                          }

                          final userId = await AuthService.getUserId();

                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not logged in')),
                            );
                            return;
                          }

                          final pickupDateForBackend =
                              '${pickupDate!.year}-${pickupDate!.month.toString().padLeft(2, '0')}-${pickupDate!.day.toString().padLeft(2, '0')}';

                          final res = await ApiService.requestAdoption(
                            int.parse(adoption['id'].toString()),
                            {
                              'user_id': userId,
                              'requester_name': nameController.text.trim(),
                              'requester_phone': phoneController.text.trim(),
                              'requester_address': addressController.text.trim(),
                              'pickup_date': pickupDateForBackend,
                            },
                          );

                          if (!context.mounted) return;

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                res['success'] == true
                                    ? 'Adoption request sent'
                                    : res['message'] ?? 'Failed to send request',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3293B3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Confirm Request',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bookingField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor: const Color(0xFFEAF1F1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF3293B3), width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _textOwner(context),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text(
                        'Text Owner',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3293B3),
                        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                        side: const BorderSide(color: Color(0xFF3293B3)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3293B3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => _showBookingSheet(context),
                      child: Text(
                        'Check Booking',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),

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
