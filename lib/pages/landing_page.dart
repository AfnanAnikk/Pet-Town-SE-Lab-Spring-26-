import 'package:flutter/material.dart';
import '../widgets/pulsing_image.dart';
import '../widgets/rolling_text_button.dart';
import 'auth/login_main_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Scattered Images Background
            PulsingImage(
              image: const AssetImage('assets/images/tleft_cat.png'),
              width: size.width * 0.22,
              height: size.height * 0.15,
              top: 30,
              left: -17,
              duration: const Duration(milliseconds: 1800),
              delay: const Duration(milliseconds: 0),
            ),
            PulsingImage(
              image: const AssetImage('assets/images/middle_cat.png'),
              width: size.width * 0.45,
              height: size.height * 0.28,
              top: 10,
              left: 100,
              duration: const Duration(milliseconds: 2200),
              delay: const Duration(milliseconds: 500),
            ),
            PulsingImage(
              image: const AssetImage('assets/images/tright_dog.png'),
              width: size.width * 0.28,
              height: size.height * 0.16,
              top: 50,
              right: -17,
              duration: const Duration(milliseconds: 1600),
              delay: const Duration(milliseconds: 200),
            ),
            PulsingImage(
              image: const AssetImage('assets/images/bleft_cat.png'),
              width: size.width * 0.30,
              height: size.height * 0.15,
              top: size.height * 0.30,
              left: -15,
              duration: const Duration(milliseconds: 2000),
              delay: const Duration(milliseconds: 700),
            ),

            // Foreground Content
            Align(
              alignment: const Alignment(0, 0.4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.8),
                      Colors.white,
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Placeholder
                    Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                    
                    // Main Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(
                            text: 'All-in-one platform for\n',
                            style: TextStyle(color: Color(0xFF2596BE)), //Brand
                          ),
                          TextSpan(
                            text: 'our beloved pets.',
                            style: TextStyle(color: Color(0xFF374957)), //2nd
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Rolling Text Button
                    RollingTextButton(
                      texts: const [
                        'Get Your Next Inspiration',
                        'Get Your Next Playdate',
                        'Get Your Next Vet Visit',
                        'Shop for Groceries',
                        'Adopt A Pet',
                        'Join Pet Town Community'
                      ],
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginMainPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // Terms and Privacy Footer
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontFamily: 'System',
                        ),
                        children: [
                          TextSpan(text: 'By continuing, you agree to our '),
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
          ],
        ),
      ),
    );
  }
}
