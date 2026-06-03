import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class SalonListPage extends StatefulWidget {
  const SalonListPage({super.key});

  @override
  State<SalonListPage> createState() => SalonListPageState();
}

class SalonListPageState extends State<SalonListPage> {
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
          'Pet Salon',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 127, 8),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}