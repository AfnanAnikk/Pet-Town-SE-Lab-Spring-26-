import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';


class UserHistoryPage extends StatefulWidget {
  const UserHistoryPage({super.key});

  @override
  State<UserHistoryPage> createState() => _UserHistoryPageState();
}

class _UserHistoryPageState extends State<UserHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      setState(() {
        _errorMessage = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final vetResult = await ApiService.getUserBookings(userId);
      final salonResult = await ApiService.getUserSalonBookings(userId);
      
      List<dynamic> allBookings = [];
      
      if (vetResult['success'] && vetResult['data'] != null) {
        final vetBookings = (vetResult['data'] as List).map((b) => {...b, 'provider_type': 'vet'}).toList();
        allBookings.addAll(vetBookings);
      }
      
      if (salonResult['success'] && salonResult['data'] != null) {
        final salonBookings = (salonResult['data'] as List).map((b) => {...b, 'provider_type': 'salon'}).toList();
        allBookings.addAll(salonBookings);
      }
      
      allBookings.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      
      setState(() {
        _bookings = allBookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showReviewSheet(dynamic booking) {
    int _rating = 5;
    TextEditingController _reviewController = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F1F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Review ${booking['provider_type'] == 'salon' ? (booking['salon_name'] ?? 'Salon') : (booking['vet_name'] ?? 'Vet')}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3293B3)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'How was your experience?',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF3293B3).withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 34,
                              ),
                              onPressed: () {
                                setSheetState(() {
                                  _rating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your review here...',
                        hintStyle: const TextStyle(color: Colors.black38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9),
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: const Color(0xFF3293B3).withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF3293B3), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3293B3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSubmitting ? null : () async {
                          if (_reviewController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a review')));
                            return;
                          }
                          setSheetState(() {
                            _isSubmitting = true;
                          });

                          Map<String, dynamic> res;
                          if (booking['provider_type'] == 'salon') {
                            res = await ApiService.addSalonReview(
                              booking['salon_id'].toString(),
                              booking['id'].toString(),
                              _rating.toDouble(),
                              _reviewController.text.trim(),
                            );
                          } else {
                            res = await ApiService.addVetReview(
                              booking['vet_id'].toString(),
                              booking['id'].toString(),
                              _rating.toDouble(),
                              _reviewController.text.trim(),
                            );
                          }

                          setSheetState(() {
                            _isSubmitting = false;
                          });

                          if (res['success']) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review submitted successfully!')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to submit review')));
                          }
                        },
                        child: _isSubmitting
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Submit Review', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildBookingCard(dynamic booking) {
    final bool isSalon = booking['provider_type'] == 'salon';
    final String status = booking['status'] ?? 'pending';
    final hasReviewed = booking['has_reviewed'] == true ||
    booking['has_reviewed'] == 1 ||
    booking['has_reviewed'].toString() == 'true';
    final profileImageUrl = booking['profile_picture_url'];
    debugPrint('BOOKING DEBUG: $booking');
    debugPrint('status=$status has_reviewed=${booking['has_reviewed']} hasReviewed=$hasReviewed');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3293B3).withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                backgroundImage: profileImageUrl != null && profileImageUrl.toString().isNotEmpty
                    ? NetworkImage(profileImageUrl.toString())
                    : null,
                child: profileImageUrl == null || profileImageUrl.toString().isEmpty
                    ? Icon(
                        isSalon ? Icons.content_cut : Icons.medical_services,
                        color: const Color(0xFF3293B3),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSalon ? (booking['salon_name'] ?? 'Unknown Salon') : (booking['vet_name'] ?? 'Unknown Vet'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3293B3)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking['service_type'] ?? 'Service',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status == 'pending' ? Colors.orange.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: status == 'pending' ? Colors.orange.shade800 : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white, thickness: 1.5),
          ),
          _premiumInfoRow(Icons.calendar_today, '${booking['booking_date']} at ${booking['slot_time']}'),
          const SizedBox(height: 10),
          _premiumInfoRow(Icons.pets, 'Pet: ${booking['pet_name']} (${booking['pet_species']})'),
          const SizedBox(height: 10),
          _premiumInfoRow(
            isSalon ? Icons.spa : Icons.healing,
            isSalon ? 'Service: ${booking['service_name'] ?? 'Grooming'}' : 'Concern: ${booking['concern'] ?? ''}',
          ),
          if ((status == 'accepted' || status == 'completed') && !hasReviewed) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                label: const Text('Leave a Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3293B3),
                  side: const BorderSide(color: Color(0xFF3293B3)),
                  backgroundColor: Colors.white.withValues(alpha: 0.65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _showReviewSheet(booking),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _premiumInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF3293B3)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.3),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking History',
          style: TextStyle(
            color: Color(0xFF374957),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: _bookings.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'No bookings found.',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      return _buildBookingCard(_bookings[index]);
                    },
                  ),
            ),
            bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }
}
