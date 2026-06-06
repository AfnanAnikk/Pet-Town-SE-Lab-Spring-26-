import 'package:flutter/material.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();

  bool _isLoading = false;
  
  String _paymentMethod = 'Cash on Delivery';
  double _tipAmount = 0.0;
  int _discountPercent = 0;
  String? _appliedCouponCode;

  final double _serviceFee = 20.0;
  final double _packagingFee = 10.0;
  
  double get _subtotal => CartService().subtotal;
  double get _discountAmount => _subtotal * (_discountPercent / 100.0);
  double get _vat => (_subtotal - _discountAmount) * 0.05; // 5% VAT
  double get _total => (_subtotal - _discountAmount) + _serviceFee + _packagingFee + _vat + _tipAmount;

  Future<void> _placeOrder() async {
    final cart = CartService();
    if (cart.items.isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address is required')));
      return;
    }

    final userId = await AuthService.getUserId();
    if (userId == null) return;

    setState(() => _isLoading = true);

    final items = cart.items.map((i) => {
      'productId': i.product['id'],
      'quantity': i.quantity,
      'price': i.price,
    }).toList();

    debugPrint('STORE ID: ${cart.storeId}');
    debugPrint('ORDER ITEMS: $items');

    final res = await ApiService.createOrder({
      'userId': userId,
      'storeId': cart.storeId,
      'items': items,
      'totalPrice': _total,
      'deliveryAddress': _addressController.text.trim(),
      'paymentMethod': _paymentMethod,
      'tipAmount': _tipAmount,
      'couponCode': _appliedCouponCode,
    });
  
    setState(() => _isLoading = false);

    if (res['success']) {
      cart.clearCart();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Order Placed!'),
            content: const Text('Your order has been successfully placed.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // pop dialog
                  Navigator.pop(ctx); // pop checkout
                  Navigator.pop(ctx); // pop cart
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Checkout', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'Delivery Address',
                    icon: Icons.location_on_outlined,
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(hintText: 'Enter full delivery address', border: InputBorder.none),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Payment Method',
                    icon: Icons.payments_outlined,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _paymentMethod,
                        isExpanded: true,
                        items: ['Cash on Delivery', 'Credit Card', 'bKash'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Tip Rider',
                    icon: Icons.motorcycle_outlined,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [0.0, 10.0, 20.0, 50.0].map((amount) {
                        final isSelected = _tipAmount == amount;
                        return ChoiceChip(
                          label: Text(amount == 0 ? 'No tip' : '৳$amount'),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _tipAmount = amount);
                          },
                          selectedColor: const Color(0xFF3293B3).withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Available Vouchers',
                    icon: Icons.local_offer_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Enter voucher code',
                                  border: InputBorder.none,
                                ),
                                enabled: _appliedCouponCode == null,
                              ),
                            ),
                            if (_appliedCouponCode == null)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3293B3),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  final code = _couponController.text.trim();
                                  if (code.isEmpty) return;
                                  
                                  setState(() => _isLoading = true);
                                  final cart = CartService();
                                  
                                  final res = await ApiService.validateCoupon(
                                    cart.storeId!,
                                    code,
                                    _subtotal,
                                  );
                                  
                                  setState(() => _isLoading = false);
                                  
                                  if (res['success'] && res['data']?['valid'] == true) {
                                    final coupon = res['data']['coupon'];
                                    setState(() {
                                      _discountPercent = coupon['discount_percent'] ?? 0;
                                      _appliedCouponCode = coupon['code'];
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Voucher applied! ${coupon['discount_percent']}% off')),
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
                                child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            else
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _discountPercent = 0;
                                    _appliedCouponCode = null;
                                    _couponController.clear();
                                  });
                                },
                                child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                        if (_appliedCouponCode != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Coupon "$_appliedCouponCode" applied successfully!',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Order Summary',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', _subtotal),
                        if (_discountAmount > 0) _buildSummaryRow('Voucher Discount ($_discountPercent%)', _discountAmount, isDiscount: true),
                        _buildSummaryRow('Service Fee', _serviceFee),
                        _buildSummaryRow('Packaging Fee', _packagingFee),
                        _buildSummaryRow('VAT (5%)', _vat),
                        if (_tipAmount > 0) _buildSummaryRow('Rider Tip', _tipAmount),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('৳${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3293B3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Place Order (৳${_total.toStringAsFixed(2)})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3293B3), size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(isDiscount ? '-৳${amount.toStringAsFixed(2)}' : '৳${amount.toStringAsFixed(2)}',
               style: TextStyle(color: isDiscount ? Colors.green : Colors.black, fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
