import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisteredPage extends StatelessWidget {
  const RegisteredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Color(0xFF3293B3),
              labelColor: Color(0xFF3293B3),
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Booked Pets & Shelters'),
                Tab(text: 'My Re-Homes'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                Center(child: Text("You haven't booked any pets or shelters yet.")),
                Center(child: Text("You haven't placed any pets for re-homing.")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
