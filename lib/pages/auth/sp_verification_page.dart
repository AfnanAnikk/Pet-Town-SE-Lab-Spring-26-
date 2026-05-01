import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';

class SpVerificationPage extends StatefulWidget {
  const SpVerificationPage({super.key});

  @override
  State<SpVerificationPage> createState() => _SpVerificationPageState();
}

class _SpVerificationPageState extends State<SpVerificationPage> {
  bool _agreedToTerms = false;

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

  Widget _buildTextField(String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
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

  Widget _buildUploadBox(String title) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
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
              Icons.image_outlined,
              color: Colors.black54,
              size: 24,
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
                        'Help us verify your business.',
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
              _buildTextField('Name'),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildUploadBox('Upload NID\nFront'),
                  const SizedBox(width: 16),
                  _buildUploadBox('Upload NID\nBack'),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('NID Number'),

              // Business Verification
              _buildSectionTitle('Business Verification (At least one)'),
              Row(
                children: [
                  _buildUploadBox('Upload TIN\nCertificate'),
                  const SizedBox(width: 16),
                  _buildUploadBox('Upload Trade\nCertificate'),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('TIN Certificate Number'),
              _buildTextField('Trade License Number'),

              // Professional License
              _buildSectionTitle('Professional License (Vet/Clinic)'),
              Row(
                children: [
                  _buildUploadBox('Upload BVC\nCertificate'),
                  const SizedBox(width: 16),
                  _buildUploadBox('Upload Other\nCertificate\n(optional)'),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField('BVC Registration Number'),
              _buildTextField('Other License Name/Number (optional)'),
              const SizedBox(height: 14),

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
              PrimaryButton(
                text: 'Sign up',
                onPressed: () {},
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
