import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class AdoptionPage extends StatefulWidget {
  const AdoptionPage({super.key});

  @override
  State<AdoptionPage> createState() => AdoptionPageState();
}

class AdoptionPageState extends State<AdoptionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Adoption',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 11, 108),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}