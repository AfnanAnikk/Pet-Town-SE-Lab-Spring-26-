import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374957)),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(
            color: Color(0xFF374957),
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(
          '''
Welcome to PetTown.

By creating an account, you agree to follow these simple rules:

1. Use the app respectfully and responsibly.

2. Do not post fake, harmful, abusive, or unrelated content.

3. Do not share false information about pets, vets, stores, or users.

4. You are responsible for the information you provide in your account.

5. PetTown may remove posts, products, or accounts that break our rules.

6. Vet, store, and booking information should be honest and accurate.

7. PetTown is not responsible for disputes between users, vets, or sellers, but we may take action if rules are broken.

8. Your data will be used only to provide app features such as account login, posts, messaging, bookings, and marketplace services.

9. Do not misuse the app, spam users, or try to damage the system.

10. By signing up, you agree to these Terms and Conditions.

Thank you for keeping PetTown safe and friendly.
''',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF374957),
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }
}