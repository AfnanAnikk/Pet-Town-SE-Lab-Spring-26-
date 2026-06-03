import 'package:flutter/material.dart';
import 'package:pet_town/pages/adoption/adoption_page.dart';
import 'package:pet_town/pages/events/event_page.dart';
import 'package:pet_town/pages/salon/salon_list_page.dart';
import '../pages/profile/user_profile_page.dart';
import '../pages/vet/vet_list_page.dart';
import '../pages/marketplace/marketplace_home_page.dart';
import '../pages/search/global_search_page.dart';
import '../pages/profile/notifications_page.dart';
import '../services/auth_service.dart';

class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final bool isOutsideTab;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isOutsideTab = false,
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar> {
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return;

    final res = await AuthService.getProfile(userId);

    if (res['success'] == true && res['data'] != null) {
      final user = res['data']['user'];

      if (mounted) {
        setState(() {
          _profilePictureUrl = user['profile_picture_url'];
        });
      }
    }
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showFeatureMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 24, right: 24, bottom: 65),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _featureButton(context, 'assets/images/vet1.png', 'Pet Vet', const VetListPage()),
                _featureButton(context, 'assets/images/marketplace.png', 'Marketplace', const MarketplaceHomePage()),
                _featureButton(context, 'assets/images/adoption.png', 'Adoption', const AdoptionPage()),
                _featureButton(context, 'assets/images/events.png', 'Events', const EventPage()),
                _featureButton(context, 'assets/images/grooming.png', 'Grooming', const SalonListPage()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _featureButton(BuildContext context, String asset, String tooltip, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _go(context, page);
      },
      child: Tooltip(
        message: tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Image.asset(asset, width: 28, height: 28),
        ),
      ),
    );
  }

  Widget _comingSoon(BuildContext context, String asset, String name) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name Feature Coming Soon!')),
        );
      },
      child: Tooltip(
        message: name,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Image.asset(asset, width: 28, height: 28),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    final hasProfileImage =
        _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: const Color(0xFFE0E0E0),
        backgroundImage: hasProfileImage
            ? NetworkImage(_profilePictureUrl!)
            : null,
        child: hasProfileImage
            ? null
            : const Icon(Icons.person, size: 16, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: widget.isOutsideTab
          ? const Color.fromARGB(255, 124, 124, 124)
          : Colors.black,
      unselectedItemColor: const Color.fromARGB(255, 124, 124, 124),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 8,
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 1) {
          if (widget.currentIndex != 1) {
            _go(context, const GlobalSearchPage());
          }
        } else if (index == 2) {
          _showFeatureMenu(context);
        } else if (index == 3) {
          if (widget.currentIndex != 3) {
            _go(context, const NotificationsPage());
          }
        } else if (index == 4) {
          if (widget.currentIndex != 4) {
            _go(context, const UserProfilePage());
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feature Coming Soon!')),
          );
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/home.png', width: 28, height: 28),
          activeIcon: Image.asset(
            widget.isOutsideTab ? 'assets/images/home.png' : 'assets/images/home1.png',
            width: 28,
            height: 28,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/search.png', width: 28, height: 28),
          activeIcon: Image.asset(
            widget.isOutsideTab ? 'assets/images/search.png' : 'assets/images/search1.png',
            width: 28,
            height: 28,
          ),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/features.png', width: 28, height: 28),
          activeIcon: Image.asset(
            widget.isOutsideTab ? 'assets/images/features.png' : 'assets/images/features1.png',
            width: 28,
            height: 28,
          ),
          label: 'Features',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/notifications.png', width: 28, height: 28),
          activeIcon: Image.asset(
            widget.isOutsideTab ? 'assets/images/notifications.png' : 'assets/images/notifications1.png',
            width: 28,
            height: 28,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _buildProfileIcon(),
          activeIcon: _buildProfileIcon(),
          label: 'Profile',
        ),
      ],
    );
  }
}