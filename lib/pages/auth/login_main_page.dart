import 'package:flutter/material.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';
import 'user_signup_page.dart';
import 'sp_signup_page.dart';

class LoginMainPage extends StatelessWidget {
  const LoginMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374957),
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
              const SizedBox(height: 5),
              const Text(
                'Sign up or log in to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              // Social Logins
              PrimaryButton(
                text: 'Continue with Google',
                onPressed: () {},
                isOutlined: true,
                textColor: Colors.black,
                color: const Color.fromARGB(255, 0, 0, 0), // Google color
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Continue with Facebook',
                onPressed: () {},
                color: const Color(0xFF3B5998), // Facebook color
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Continue with Apple ID',
                onPressed: () {},
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              const SizedBox(height: 16),

              // -or- divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              PrimaryButton(
                text: 'Log In',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Sign Up',
                isOutlined: true,
                color: const Color(0xFF8C52FF), // Purple outline
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserSignupPage()),
                  );
                },
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Sign Up As A Business',
                isOutlined: true,
                color: const Color(0xFFFF7A7A), // Pinkish outline
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpSignupPage()),
                  );
                },
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'Join As Service Provider',
                isOutlined: true,
                color: const Color(0xFF3293B3), // Teal outline
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SpSignupPage()),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Footer
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontFamily: 'System',
                  ),
                  children: [
                    TextSpan(text: 'By signing up, you agree to our '),
                    TextSpan(
                      text: 'Terms and Conditions\n',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                    TextSpan(text: 'and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
