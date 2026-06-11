import 'package:flutter/material.dart';

class SpTermsConditionsPage extends StatelessWidget {
  const SpTermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374957)),
        title: const Text(
          'Service Provider Terms',
          style: TextStyle(
            color: Color(0xFF374957),
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            SizedBox(height: 24),

            Center(
              child: Text(
                'IMPORTANT',
                style: TextStyle(
                  fontSize: 34,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3293B3),
                ),
              ),
            ),

            SizedBox(height: 18),

            Center(
              child: Text(
                'You agree to pay 10% of your income earned through PetTown to us.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.4,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),

            SizedBox(height: 32),

            Text(
              '''
By registering as a service provider on PetTown, you agree to the following terms:

1. You must provide correct and honest business, service, and identity information.

2. You must upload valid documents for verification.

3. You are responsible for the services, products, bookings, prices, and information you provide.

4. You agree to pay PetTown 10% of the income you earn through the platform.

5. Payments, commissions, or service charges must be handled honestly and on time.

6. You must not scam, mislead, overcharge, or provide false information to users.

7. PetTown may review, suspend, or remove your service provider account if you break the rules.

8. PetTown may remove products, services, bookings, or content that violate app policies.

9. You must treat customers respectfully and professionally.

10. By continuing, you confirm that you understand and accept these terms.
''',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF374957),
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}