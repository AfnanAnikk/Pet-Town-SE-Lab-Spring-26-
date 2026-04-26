import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';
import 'sp_verification_page.dart';

class SpSignupPage extends StatefulWidget {
  const SpSignupPage({super.key});

  @override
  State<SpSignupPage> createState() => _SpSignupPageState();
}

class _SpSignupPageState extends State<SpSignupPage> {
  bool _agreedToTerms = true;
  String _selectedServiceType = 'Pet Salon';

  Widget _buildServiceTypeOption(String title) {
    bool isSelected = _selectedServiceType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedServiceType = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C3E50),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
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
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
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

              // Form Fields
              const CustomTextField(
                label: 'Service/ Vet Name',
                hintText: 'PawPatrol',
              ),
              const SizedBox(height: 8),
              // Service Type
              const Text(
                'Service Type',
                style: TextStyle(
                  color: Color(0xFF3293B3),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildServiceTypeOption('Pet Salon'),
                  _buildServiceTypeOption('Vet Clinic'),
                  _buildServiceTypeOption('Vet'),
                ],
              ),
              const SizedBox(height: 8),
              const CustomTextField(
                label: 'Email',
                hintText: 'user@gmail.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              const CustomTextField(
                label: 'Password',
                hintText: '••••••••••',
                isPassword: true,
              ),
              const SizedBox(height: 8),
              const CustomTextField(
                label: 'Phone Number',
                hintText: '019••••••••',
                keyboardType: TextInputType.phone,
              ),
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpVerificationPage(),
                    ),
                  );
                },
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
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
