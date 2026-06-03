import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import 'new_friend_page.dart';
import 'rehome_page.dart';
import 'registered_page.dart';
import 'shelters_page.dart';
import 'package:google_fonts/google_fonts.dart';

class AdoptionPage extends StatefulWidget {
  const AdoptionPage({super.key});

  @override
  State<AdoptionPage> createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              'Adoption',
              style: GoogleFonts.outfit(
                color: const Color(0xFF3293B3),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3293B3), width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF3293B3),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 12),
                          SizedBox(width: 4),
                          Text('New Friend', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home, size: 12),
                          SizedBox(width: 4),
                          Text('Re-Home', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, size: 12),
                          SizedBox(width: 4),
                          Text('Registered', overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite, size: 12),
                          SizedBox(width: 4),
                          Text('Shelter', overflow: TextOverflow.ellipsis),
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
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Match segmented control feel
        children: const [
          NewFriendPage(),
          RehomePage(),
          RegisteredPage(),
          SheltersPage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}