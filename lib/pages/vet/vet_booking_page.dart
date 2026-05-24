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
  
  String? _appliedVoucherCode;
  int _discountPercent = 0;
  int _discountAmount = 0;
  List<dynamic> _availableVouchers = [];
  bool _isLoadingVouchers = false;

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
      'voucherCode': _appliedVoucherCode,
      'discountAmount': _discountAmount,
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
    _loadAvailableVouchers();

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
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, color: Colors.black87, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Voucher',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (_appliedVoucherCode != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_appliedVoucherCode ($_discountPercent% OFF)',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _appliedVoucherCode = null;
                                          _discountPercent = 0;
                                          _discountAmount = 0;
                                        });
                                      },
                                      child: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'No voucher applied',
                                  style: TextStyle(fontSize: 15, color: Colors.black54),
                                ),
                              ]
                            ],
                          ),
                        ),
                        if (_appliedVoucherCode == null)
                          TextButton(
                            onPressed: _showVoucherBottomSheet,
                            child: const Text(
                              'Apply',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3FA9F5),
                              ),
                            ),
                          ),
                      ],
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
                        if (_discountAmount > 0) ...[
                          Row(
                            children: [
                              Text(
                                'BDT ${widget.vet.price}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'BDT ${widget.vet.price - _discountAmount}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Saved BDT $_discountAmount ($_discountPercent% off)',
                            style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          Text(
                            'BDT ${widget.vet.price}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
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
  Future<void> _loadAvailableVouchers() async {
    setState(() {
      _isLoadingVouchers = true;
    });
    final res = await ApiService.getAvailableVetVouchers(int.tryParse(widget.vet.id) ?? 0);
    if (res['success']) {
      setState(() {
        _availableVouchers = res['data'] ?? [];
        _isLoadingVouchers = false;
      });
    } else {
      setState(() {
        _isLoadingVouchers = false;
      });
    }
  }

  void _showVoucherBottomSheet() {
    final manualCodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Apply Voucher',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Manual code entry
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: manualCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter Voucher Code',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF3FA9F5)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final code = manualCodeController.text.trim();
                          if (code.isEmpty) return;
                          
                          final res = await ApiService.validateVetVoucher(int.tryParse(widget.vet.id) ?? 0, code);
                          if (res['success'] && res['data']?['valid'] == true) {
                            final voucher = res['data']['voucher'];
                            setState(() {
                              _appliedVoucherCode = voucher['code'];
                              _discountPercent = voucher['discount_percent'] ?? 0;
                              _discountAmount = ((widget.vet.price * _discountPercent) / 100).round();
                            });
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Voucher applied! $_discountPercent% off')),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(res['data']?['message'] ?? res['message'] ?? 'Invalid voucher code')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3FA9F5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Available Vouchers',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374957)),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: _isLoadingVouchers
                        ? const Center(child: CircularProgressIndicator())
                        : _availableVouchers.isEmpty
                            ? const Center(
                                child: Text(
                                  'No vouchers available right now.',
                                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _availableVouchers.length,
                                itemBuilder: (context, index) {
                                  final v = _availableVouchers[index];
                                  final expiry = v['expires_at'] != null ? DateTime.tryParse(v['expires_at']) : null;
                                  final expiryStr = expiry != null ? '${expiry.day}/${expiry.month}/${expiry.year}' : 'Never';
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 1,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE8F5E9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${v['discount_percent']}% OFF',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  v['code'],
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF374957)),
                                                ),
                                                const SizedBox(height: 4),
                                                Text('Expires: $expiryStr', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _appliedVoucherCode = v['code'];
                                                _discountPercent = v['discount_percent'] ?? 0;
                                                _discountAmount = ((widget.vet.price * _discountPercent) / 100).round();
                                              });
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Voucher applied! $_discountPercent% off')),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            child: const Text('Use', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
