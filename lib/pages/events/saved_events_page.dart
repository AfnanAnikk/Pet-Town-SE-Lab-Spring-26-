import 'package:flutter/material.dart';
import '../../widgets/event_card.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'event_detail_page.dart';
import 'event_discovery_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

class SavedEventsPage extends StatefulWidget {
  final bool embedded;
  const SavedEventsPage({super.key, this.embedded = false});

  @override
  State<SavedEventsPage> createState() => _SavedEventsPageState();
}

class _SavedEventsPageState extends State<SavedEventsPage> {
  List<EventModel> _events = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = await AuthService.getUserId();
    if (!mounted) return;
    setState(() { _userId = uid; _isLoading = true; });
    if (uid == null) { setState(() => _isLoading = false); return; }

    final res = await ApiService.getSavedEvents(uid);
    if (!mounted) return;
    List<EventModel> list = [];
    if (res['success'] == true) {
      final raw = res['data'];
      final List? rawList = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) {
        list = rawList.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    setState(() { _events = list; _isLoading = false; });
  }

  Future<void> _unsave(EventModel ev) async {
    if (_userId == null) return;
    await ApiService.unsaveEventBookmark(ev.id, _userId!);
    setState(() => _events.removeWhere((e) => e.id == ev.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Removed "${ev.title}" from saved', style: const TextStyle(fontFamily: 'Outfit')),
        action: SnackBarAction(label: 'Undo', textColor: Colors.white, onPressed: () async {
          await ApiService.saveEventBookmark(ev.id, _userId!);
          setState(() => _events.insert(0, ev));
        }),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator(color: _brandColor))
        : _events.isEmpty
            ? _emptyState()
            : RefreshIndicator(
                color: _brandColor, onRefresh: _load,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                      childAspectRatio: 0.72),
                  itemCount: _events.length,
                  itemBuilder: (ctx, i) => EventCard(
                    event: _events[i],
                    isSaved: true,
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                        builder: (_) => EventDetailPage(eventId: _events[i].id))),
                    onSave: () => _unsave(_events[i]),
                  ),
                ),
              );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Saved Events', style: TextStyle(fontFamily: 'Outfit',
            fontSize: 20, fontWeight: FontWeight.bold, color: _brandColor)),
        actions: [const Icon(Icons.bookmark, color: _brandColor, size: 22),
            const SizedBox(width: 16)],
      ),
      body: body,
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.bookmark_outline, size: 72, color: Colors.grey.shade300),
    const SizedBox(height: 16),
    Text('No saved events yet', style: TextStyle(fontFamily: 'Outfit',
        fontSize: 17, color: Colors.grey.shade500)),
    const SizedBox(height: 8),
    Text('Bookmark events to find them here', style: TextStyle(fontFamily: 'Outfit',
        fontSize: 14, color: Colors.grey.shade400)),
    const SizedBox(height: 20),
    ElevatedButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EventDiscoveryPage())),
      style: ElevatedButton.styleFrom(backgroundColor: _brandColor, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
      child: const Text('Discover Events', style: TextStyle(fontFamily: 'Outfit',
          color: Colors.white, fontWeight: FontWeight.w600)),
    ),
  ]));
}
