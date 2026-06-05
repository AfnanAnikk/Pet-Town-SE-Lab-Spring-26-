import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_category_chip.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import 'event_detail_page.dart';
import 'event_search_page.dart';
import 'event_discovery_page.dart';
import 'create_event_page.dart';
import 'my_events_page.dart';
import 'saved_events_page.dart';
import 'event_invitations_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

const List<String> _categories = [
  'All', 'Adoption', 'Vaccination', 'Meetup', 'Training',
  'Competition', 'Outdoor', 'Awareness', 'Seminar', 'Fundraising', 'Other',
];

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EventModel> _trending = [];
  List<EventModel> _upcoming = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final trendRes = await ApiService.getTrendingEvents();
      final upcomingRes = await ApiService.getEvents(
        status: 'upcoming',
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        limit: 30,
      );
      if (mounted) {
        setState(() {
          _trending = _parseEvents(trendRes);
          _upcoming = _parseEvents(upcomingRes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load events: $e',
              style: const TextStyle(fontFamily: 'Outfit')),
              backgroundColor: Colors.red.shade400));
      }
    }
  }

  List<EventModel> _parseEvents(Map<String, dynamic> res) {
    if (res['success'] != true) return [];
    final data = res['data'];
    // Direct list (backend returns plain array)
    if (data is List) {
      return data.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    // Double-wrapped: _handleResponse wraps body, but events backend already
    // returns {success, data: [...]}, so data here is that inner map.
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> _onCategorySelected(String cat) async {
    setState(() => _selectedCategory = cat);
    await _loadData();
  }

  void _openDetail(EventModel event) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                MyEventsPage(embedded: true),
                SavedEventsPage(embedded: true),
                EventInvitationsPage(embedded: true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar:
          const AppBottomNavBar(currentIndex: 2, isOutsideTab: true),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Events',
          style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _brandColor)),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: _secondary),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EventSearchPage())),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _brandColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _brandColor,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Discover'),
          Tab(text: 'My Events'),
          Tab(text: 'Saved'),
          Tab(text: 'Invites'),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return RefreshIndicator(
      color: _brandColor,
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : CustomScrollView(
              slivers: [
                // Category chips
                SliverToBoxAdapter(child: _buildCategoryChips()),
                // Trending section
                if (_trending.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _sectionHeader('🔥 Trending This Week', onSeeAll: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EventDiscoveryPage()));
                  })),
                  SliverToBoxAdapter(child: _buildTrendingRow()),
                ],
                // Upcoming section
                SliverToBoxAdapter(
                    child: _sectionHeader('📅 Upcoming Events', onSeeAll: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EventDiscoveryPage()));
                })),
                if (_upcoming.isEmpty)
                  SliverFillRemaining(child: _emptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventCard(
                            event: _upcoming[i],
                            onTap: () => _openDetail(_upcoming[i]),
                            isSaved: false,
                          ),
                        ),
                        childCount: _upcoming.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) => EventCategoryChip(
          label: _categories[i],
          isSelected: _selectedCategory == _categories[i],
          onTap: () => _onCategorySelected(_categories[i]),
        ),
      ),
    );
  }

  Widget _buildTrendingRow() {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _trending.length,
        itemBuilder: (ctx, i) => SizedBox(
          width: 240,
          child: EventCard(
            event: _trending[i],
            onTap: () => _openDetail(_trending[i]),
            isSaved: false,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _secondary)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: _brandColor,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No events found',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Be the first to create one!',
              style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateEventPage()));
        if (result == true && mounted) _loadData();
      },
      backgroundColor: _brandColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Create Event',
          style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              color: Colors.white)),
    );
  }
}