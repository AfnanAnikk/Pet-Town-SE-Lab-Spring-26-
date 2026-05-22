import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';
import '../../services/api_service.dart';

class SpVerificationPage extends StatefulWidget {
  final int userId;
  final String serviceType;
  const SpVerificationPage({super.key, required this.userId, this.serviceType = ''});

  @override
  State<SpVerificationPage> createState() => _SpVerificationPageState();
}

class _SpVerificationPageState extends State<SpVerificationPage> {
  bool _agreedToTerms = false;
  bool _isLoading = false;
  
  final _nameController = TextEditingController();

  File? _nidFront;
  File? _nidBack;
  File? _tinCert;
  File? _tradeCert;
  File? _bvcCert;
  File? _otherCert;

  Future<void> _pickImage(Function(File) onPicked) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        onPicked(File(picked.path));
      });
    }
  }

  Future<String?> _uploadIfNotNull(File? file) async {
    if (file == null) return null;
    final res = await ApiService.uploadImage(file.path);
    if (res['success']) {
      return res['data']['url'];
    }
    return null;
  }

  Future<void> _handleVerification() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to terms')));
      return;
    }
    setState(() => _isLoading = true);

    // Upload images first
    final nidFrontUrl = await _uploadIfNotNull(_nidFront);
    final nidBackUrl = await _uploadIfNotNull(_nidBack);
    final tinUrl = await _uploadIfNotNull(_tinCert);
    final tradeUrl = await _uploadIfNotNull(_tradeCert);
    final bvcUrl = await _uploadIfNotNull(_bvcCert);
    final otherUrl = await _uploadIfNotNull(_otherCert);

    final result = await ApiService.submitVerification(
      userId: widget.userId,
      ownerName: _nameController.text,
      serviceType: widget.serviceType,
      nidFrontUrl: nidFrontUrl,
      nidBackUrl: nidBackUrl,
      tinUrl: tinUrl,
      tradeUrl: tradeUrl,
      bvcUrl: bvcUrl,
      otherUrl: otherUrl,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF3293B3),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3293B3)),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox(String title, File? selectedFile, Function(File) onPicked) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(onPicked),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade50,
          ),
          clipBehavior: Clip.hardEdge,
          child: selectedFile != null
              ? Image.file(selectedFile, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text(
                        'Verification \nDetails',
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Upload photos of your documents',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
              const SizedBox(height: 32),

              // Owner Verification
              _buildSectionTitle('Owner Verification'),
              _buildTextField('Owner Name', _nameController),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildUploadBox('NID Front', _nidFront, (f) => _nidFront = f),
                  const SizedBox(width: 16),
                  _buildUploadBox('NID Back', _nidBack, (f) => _nidBack = f),
                ],
              ),

              // Business Verification
              _buildSectionTitle('Business Verification (At least one)'),
              Row(
                children: [
                  _buildUploadBox('TIN Certificate', _tinCert, (f) => _tinCert = f),
                  const SizedBox(width: 16),
                  _buildUploadBox('Trade License', _tradeCert, (f) => _tradeCert = f),
                ],
              ),

              // Professional License
              if (widget.serviceType == 'Vet' || widget.serviceType == 'Pet Salon' || widget.serviceType == '') ...[
                _buildSectionTitle('Professional License (Vet/Clinic)'),
                Row(
                  children: [
                    _buildUploadBox('BVC Registration', _bvcCert, (f) => _bvcCert = f),
                    const SizedBox(width: 16),
                    _buildUploadBox('Other License\n(optional)', _otherCert, (f) => _otherCert = f),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Terms and Conditions
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          _agreedToTerms = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(text: 'I agreed to the all '),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: TextStyle(
                              color: Color(0xFF3293B3),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Submit for Review',
                      onPressed: _handleVerification,
                    ),
              const SizedBox(height: 10),

              // Bottom link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        color: Color(0xFF3293B3),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
