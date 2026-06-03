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
        toolbarHeight: 104,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adoption',
              style: GoogleFonts.outfit(
                color: const Color(0xFF3293B3),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              width: MediaQuery.of(context).size.width - 32,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF3293B3),
                    width: 1.2,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xFF3293B3),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(child: Text('Friend')),
                    Tab(child: Text('Re-Home')),
                    Tab(child: Text('Register')),
                    Tab(child: Text('Shelter')),
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
        children: [
          NewFriendPage(),
          RehomePage(onSubmitted: () {
            _tabController.animateTo(0);
          }),
          RegisteredPage(),
          SheltersPage(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2),
    );
  }
}