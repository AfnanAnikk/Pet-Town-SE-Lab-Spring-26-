import 'package:flutter/material.dart';

// --- Pet Details Sheet ---
class PetDetailsSheet extends StatefulWidget {
  const PetDetailsSheet({super.key});

  @override
  State<PetDetailsSheet> createState() => _PetDetailsSheetState();
}

class _PetDetailsSheetState extends State<PetDetailsSheet> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _sexController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedSpecies;
  
  void _openSpeciesSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PetSpeciesSheet(initialSpecies: _selectedSpecies),
    );
    if (result != null) {
      setState(() {
        _selectedSpecies = result;
      });
    }
  }

  Widget _buildField({required String label, String? value, VoidCallback? onTap, bool isInput = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: isInput ? 4 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: isInput
              ? TextField(
                  controller: label == 'Enter pet name' ? _nameController : 
                              label == 'Breed' ? _breedController : 
                              label == 'Sex' ? _sexController : _dobController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: label,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (value != null) ...[
                          const SizedBox(height: 4),
                          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        ]
                      ],
                    ),
                    if (onTap != null) const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3293B3)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Let's meet your pet!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3293B3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildField(label: 'Enter pet name', isInput: true),
                  _buildField(
                    label: 'Species',
                    value: _selectedSpecies ?? 'Tap to select',
                    onTap: _openSpeciesSheet,
                  ),
                  _buildField(label: 'Breed', isInput: true),
                  _buildField(label: 'Sex', isInput: true),
                  _buildField(label: 'Age (Years)', isInput: true),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _nameController.clear();
                      _breedController.clear();
                      _sexController.clear();
                      _dobController.clear();
                      setState(() => _selectedSpecies = null);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black87),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty || _selectedSpecies != null) {
                        final speciesStr = _selectedSpecies ?? 'Pet';
                        final breedStr = _breedController.text.isNotEmpty ? _breedController.text : 'Unknown Breed';
                        final sexStr = _sexController.text.isNotEmpty ? _sexController.text : 'Unknown Sex';
                        final ageStr = _dobController.text.isNotEmpty ? _dobController.text : '?';
                        final summary = '$speciesStr, $breedStr, $sexStr, $ageStr';
                        
                        Navigator.pop(context, {
                          'name': _nameController.text,
                          'species': speciesStr,
                          'summary': summary,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3FA9F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Pet Species Sheet ---
class PetSpeciesSheet extends StatefulWidget {
  final String? initialSpecies;
  const PetSpeciesSheet({super.key, this.initialSpecies});

  @override
  State<PetSpeciesSheet> createState() => _PetSpeciesSheetState();
}

class _PetSpeciesSheetState extends State<PetSpeciesSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSpecies;
  }

  final speciesList = [
    {'name': 'Dog', 'icon': Icons.pets},
    {'name': 'Cat', 'icon': Icons.catching_pokemon},
    {'name': 'Bird', 'icon': Icons.flutter_dash},
    {'name': 'Horse', 'icon': Icons.bedroom_baby}, // Placeholder icons
    {'name': 'Rabbit', 'icon': Icons.cruelty_free},
    {'name': 'Rat', 'icon': Icons.pest_control_rodent},
    {'name': 'Fish', 'icon': Icons.water},
    {'name': 'Turtle', 'icon': Icons.slow_motion_video},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3293B3)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Choose pet species",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3293B3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: speciesList.length,
                    itemBuilder: (context, index) {
                      final item = speciesList[index];
                      final isSelected = _selected == item['name'];
                      return InkWell(
                        onTap: () => setState(() => _selected = item['name'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5B67EC) : Colors.grey.shade400,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item['icon'] as IconData, size: 24, color: Colors.black87),
                              const SizedBox(width: 8),
                              Text(item['name'] as String, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                              const Spacer(),
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? Colors.transparent : Colors.black87),
                                  color: isSelected ? Colors.black87 : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selected = null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black87),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3FA9F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Concern Sheet ---
class ConcernSheet extends StatefulWidget {
  final String? initialConcern;
  const ConcernSheet({super.key, this.initialConcern});

  @override
  State<ConcernSheet> createState() => _ConcernSheetState();
}

class _ConcernSheetState extends State<ConcernSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialConcern;
  }

  final concerns = [
    {'name': 'Allergy', 'icon': Icons.face},
    {'name': 'Skin', 'icon': Icons.back_hand},
    {'name': 'Ear', 'icon': Icons.hearing},
    {'name': 'Bladder', 'icon': Icons.water_drop},
    {'name': 'Eye', 'icon': Icons.remove_red_eye},
    {'name': 'Flea', 'icon': Icons.bug_report},
    {'name': 'Internal', 'icon': Icons.monitor_weight},
    {'name': 'Health', 'icon': Icons.favorite_border},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3293B3)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Select Your Concern",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3293B3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: concerns.length,
                    itemBuilder: (context, index) {
                      final item = concerns[index];
                      final isSelected = _selected == item['name'];
                      return InkWell(
                        onTap: () => setState(() => _selected = item['name'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF5B67EC) : Colors.grey.shade400,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item['icon'] as IconData, size: 24, color: Colors.black87),
                              const SizedBox(width: 8),
                              Text(item['name'] as String, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                              const Spacer(),
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isSelected ? Colors.transparent : Colors.black87),
                                  color: isSelected ? Colors.black87 : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selected = null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black87),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3FA9F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Reason Sheet ---
class ReasonSheet extends StatefulWidget {
  final String? initialReason;
  const ReasonSheet({super.key, this.initialReason});

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialReason);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reason for visit',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3293B3)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Briefly describe your reason for visit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3FA9F5), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _controller.text.isEmpty ? null : _controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3FA9F5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Payment Method Sheet ---
class PaymentMethodSheet extends StatefulWidget {
  final String? initialMethod;
  const PaymentMethodSheet({super.key, this.initialMethod});

  @override
  State<PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<PaymentMethodSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialMethod;
  }

  Widget _buildPaymentOption({required String title, required IconData icon, bool isCard = false}) {
    final isSelected = _selected == title;
    return InkWell(
      onTap: () => setState(() => _selected = title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B67EC) : Colors.grey.shade400,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF3293B3)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Payment Method",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3293B3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildPaymentOption(title: 'Credit/Debit Card', icon: Icons.credit_card, isCard: true),
                  _buildPaymentOption(title: 'On hand', icon: Icons.payments_outlined),
                  
                  if (_selected == 'Credit/Debit Card') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.lock_outline, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Checkout with card', style: TextStyle(fontSize: 18, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Card Number',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.credit_card, color: Colors.blue), // Placeholder for card logos
                            ],
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Exp Date',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'CVV',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                      ),
                      value: 'Bangladesh',
                      items: ['Bangladesh', 'USA', 'UK'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {},
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selected = null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.black87),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3FA9F5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
