import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/event_card.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import 'event_detail_page.dart';

const _brandColor = Color(0xFF3293B3);

class EventSearchPage extends StatefulWidget {
  const EventSearchPage({super.key});

  @override
  State<EventSearchPage> createState() => _EventSearchPageState();
}

class _EventSearchPageState extends State<EventSearchPage> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  List<EventModel> _results = [];
  List<String> _recent = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recent = prefs.getStringList('event_recent_searches') ?? []);
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('event_recent_searches') ?? [];
    list.remove(query);
    list.insert(0, query);
    if (list.length > 5) list.removeLast();
    await prefs.setStringList('event_recent_searches', list);
    setState(() => _recent = list);
  }

  Future<void> _removeRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('event_recent_searches') ?? [];
    list.remove(query);
    await prefs.setStringList('event_recent_searches', list);
    setState(() => _recent = list);
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() { _results = []; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    final res = await ApiService.getEvents(search: query, limit: 20);
    if (!mounted) return;
    List<EventModel> list = [];
    if (res['success'] == true) {
      final raw = res['data'];
      final List? rawList = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) {
        list = rawList.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    setState(() { _results = list; _isLoading = false; });
    if (query.isNotEmpty) _saveRecent(query);
  }

  void _onRecentTap(String q) {
    _ctrl.text = q;
    _ctrl.selection = TextSelection.collapsed(offset: q.length);
    _onChanged(q);
  }

  @override
  Widget build(BuildContext context) {
    final query = _ctrl.text;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _ctrl, focusNode: _focusNode,
          onChanged: _onChanged,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search events…',
            hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400),
            border: InputBorder.none,
            suffixIcon: query.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 20),
                    onPressed: () { _ctrl.clear(); setState(() { _results = []; _isLoading = false; }); })
                : null,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : query.length < 2
              ? _buildRecentSearches()
              : _results.isEmpty
                  ? _buildEmptyState()
                  : _buildResults(),
    );
  }

  Widget _buildRecentSearches() {
    if (_recent.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Search for pet events', style: TextStyle(fontFamily: 'Outfit',
            fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text('Adoption drives, meetups, training & more',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey.shade400)),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('Recent Searches', style: TextStyle(fontFamily: 'Outfit',
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        ),
        ..._recent.map((q) => Dismissible(
          key: Key(q),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removeRecent(q),
          background: Container(color: Colors.red.shade50,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete_outline, color: Colors.red)),
          child: ListTile(
            leading: Icon(Icons.history, color: Colors.grey.shade400),
            title: Text(q, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15)),
            trailing: Icon(Icons.north_west, size: 16, color: Colors.grey.shade400),
            onTap: () => _onRecentTap(q),
          ),
        )),
      ],
    );
  }

  Widget _buildResults() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => EventCard(
        event: _results[i], isSaved: false,
        onTap: () => Navigator.push(ctx,
            MaterialPageRoute(builder: (_) => EventDetailPage(eventId: _results[i].id))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('🐾', style: const TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text('No events found for "${_ctrl.text}"',
          style: TextStyle(fontFamily: 'Outfit', fontSize: 16, color: Colors.grey.shade500),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text('Try a different keyword', style: TextStyle(fontFamily: 'Outfit',
          fontSize: 14, color: Colors.grey.shade400)),
    ]));
  }
}
