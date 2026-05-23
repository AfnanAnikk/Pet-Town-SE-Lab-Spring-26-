import 'package:flutter/material.dart';
import '../../models/vet_model.dart';
import 'vet_booking_sheets.dart';
import 'vet_booking_success_page.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class VetBookingPage extends StatefulWidget {
  final VetModel vet;
  final String? selectedSlot;

  const VetBookingPage({super.key, required this.vet, this.selectedSlot});

  @override
  State<VetBookingPage> createState() => _VetBookingPageState();
}

class _VetBookingPageState extends State<VetBookingPage> {
  String? selectedDate;
  String? selectedTime;
  Map<String, List<String>> availableSlotsByDate = {};
  
  Map<String, String>? petDetails;
  String? selectedConcern;
  String? reasonForVisit;
  String? paymentMethod;
  bool _isBooking = false;

  void _handleBooking() async {
    if (petDetails == null || selectedConcern == null || reasonForVisit == null || paymentMethod == null || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select a time')),
      );
      return;
    }

    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    setState(() => _isBooking = true);

    final summaryParts = petDetails!['summary']!.split(', ');

    final bookingData = {
      'userId': userId,
      'vetId': widget.vet.id,
      'petName': petDetails!['name'],
      'petSpecies': petDetails!['species'],
      'petBreed': summaryParts.length > 1 ? summaryParts[1] : '',
      'petSex': summaryParts.length > 2 ? summaryParts[2] : '',
      'petAge': summaryParts.length > 3 ? summaryParts[3] : '',
      'concern': selectedConcern,
      'reason': reasonForVisit,
      'paymentMethod': paymentMethod,
      'slotTime': selectedTime,
      'bookingDate': formattedDate.split(' at ').first,
    };

    final result = await ApiService.createBooking(bookingData);

    setState(() => _isBooking = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VetBookingSuccessPage(
            vet: widget.vet,
            dateStr: formattedDate.split(' at ').first,
            timeStr: selectedTime ?? '',
            reason: reasonForVisit ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  @override
  void initState() {
    super.initState();

    for (final slot in widget.vet.availableSlots) {
      final parts = slot.split(' at ');

      if (parts.length == 2) {
        final date = parts[0];
        final time = parts[1];

        availableSlotsByDate.putIfAbsent(date, () => []);
        availableSlotsByDate[date]!.add(time);
      }
    }

    if (widget.selectedSlot != null) {
      final parts = widget.selectedSlot!.split(' at ');

      if (parts.length == 2) {
        selectedDate = parts[0];
        selectedTime = parts[1];
      }
    }
  }

  String get formattedDate {
    if (selectedDate == null) return "Tap to select";
    if (selectedTime != null) {
      return "$selectedDate at $selectedTime";
    }
    return selectedDate!;
  }

  void _showPetSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PetDetailsSheet(),
    );
    if (result != null) {
      setState(() {
        petDetails = result;
      });
    }
  }

  void _showConcernSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConcernSheet(initialConcern: selectedConcern),
    );
    if (result != null) {
      setState(() {
        selectedConcern = result;
      });
    }
  }

  void _showReasonSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReasonSheet(initialReason: reasonForVisit),
    );
    if (result != null) {
      setState(() {
        reasonForVisit = result;
      });
    }
  }

  void _showPaymentSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentMethodSheet(initialMethod: paymentMethod),
    );
    if (result != null) {
      setState(() {
        paymentMethod = result;
      });
    }
  }

  Widget _buildField({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5E5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFB3B3)),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(fontSize: 10, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: value.contains('Tap to') ? Colors.black54 : Colors.black87,
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
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Text(
                      'Your appointment',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3FA9F5),
                      ),
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(
                      'Available Dates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  if (availableSlotsByDate.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Text(
                        'No available dates',
                        style: TextStyle(fontSize: 15, color: Colors.black54),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: availableSlotsByDate.keys.map((date) {
                          final isSelected = date == selectedDate;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDate = date;
                                selectedTime = null;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3FA9F5)
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                date,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF3FA9F5)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Time Section
                  if (selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: availableSlotsByDate[selectedDate]!.map((time) {
                            final isSelected = time == selectedTime;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTime = time;
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
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF3FA9F5) : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
              
                  _buildField(
                    icon: Icons.pets_outlined,
                    title: 'Pet',
                    value: petDetails != null ? petDetails!['summary'] ?? 'Selected' : 'Tap to select',
                    isRequired: petDetails == null,
                    onTap: _showPetSheet,
                  ),
                  
                  _buildField(
                    icon: Icons.medical_services_outlined,
                    title: 'Concern',
                    value: selectedConcern ?? 'Tap to select',
                    isRequired: selectedConcern == null,
                    onTap: _showConcernSheet,
                  ),
                  
                  _buildField(
                    icon: Icons.folder_open_outlined,
                    title: 'Reason for visit',
                    value: reasonForVisit ?? 'Tap to add',
                    isRequired: reasonForVisit == null,
                    onTap: _showReasonSheet,
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  _buildField(
                    icon: Icons.payments_outlined,
                    title: paymentMethod != null ? 'Payment Method' : 'Tap to add',
                    value: paymentMethod == 'Credit/Debit Card' ? 'Master Card ending at 7508' : (paymentMethod ?? ''),
                    isRequired: paymentMethod == null,
                    onTap: _showPaymentSheet,
                  ),
                  
                  InkWell(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: Colors.black87, size: 28),
                          const SizedBox(width: 16),
                          const Text(
                            'Apply voucher ( if any )',
                            style: TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
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
                          'BDT ${widget.vet.price}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          'Incl. tax\n${selectedDate != null && selectedTime != null ? "$selectedDate at $selectedTime" : "No slot selected"}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  _isBooking
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3FA9F5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
