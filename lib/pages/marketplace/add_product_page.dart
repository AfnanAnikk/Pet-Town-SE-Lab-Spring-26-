import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class AddProductPage extends StatefulWidget {
  final int storeId;

  const AddProductPage({super.key, required this.storeId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _discountController = TextEditingController();
  
  File? _productImage;

  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Toys', 'Accessories', 'Medicine', 'Other'];
  bool _isLoading = false;

  Future<void> _pickProductImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _productImage = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty || _productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and upload an image')));
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_productImage != null) {
      final uploadRes = await ApiService.uploadImage(_productImage!.path);
      if (uploadRes['success']) {
        imageUrl = uploadRes['data']['url'];
      } else {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadRes['message'])));
        return;
      }
    }

    final res = await ApiService.createProduct({
      'storeId': widget.storeId,
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'category': _selectedCategory,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'originalPrice': double.tryParse(_originalPriceController.text) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'discountPercent': int.tryParse(_discountController.text) ?? 0,
      'imagePath': imageUrl,
    });

    setState(() => _isLoading = false);

    if (res['success']) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Product', style: TextStyle(color: Color(0xFF374957))),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Product Image *'),
                  GestureDetector(
                    onTap: _pickProductImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _productImage != null
                          ? Image.file(_productImage!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text('Upload Product Photo', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                  _buildLabel('Product Name *'),
                  _buildTextField(_nameController, 'e.g. Premium Dog Food 5kg'),
                  
                  _buildLabel('Category *'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ),
                  
                  _buildLabel('Selling Price (৳) *'),
                  _buildTextField(_priceController, 'e.g. 500', keyboardType: TextInputType.number),
                  
                  _buildLabel('Original Price (৳) - Optional'),
                  _buildTextField(_originalPriceController, 'e.g. 600', keyboardType: TextInputType.number),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Quantity *'),
                            _buildTextField(_quantityController, 'e.g. 50', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Discount %'),
                            _buildTextField(_discountController, 'e.g. 10', keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  _buildLabel('Product Description'),
                  _buildTextField(_descController, 'Describe your product...', maxLines: 4),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3293B3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Product', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF374957))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
