import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/event_notifier.dart';
import '../../widgets/event_status_badge.dart';
import 'event_detail_page.dart';
import 'event_discovery_page.dart';

const _brandColor  = Color(0xFF3293B3);
const _secondary   = Color(0xFF374957);
const _bgColor     = Color(0xFFF5F7FA);

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
    EventChangeNotifier.instance.addListener(_onEventChanged);
  }

  @override
  void dispose() {
    EventChangeNotifier.instance.removeListener(_onEventChanged);
    super.dispose();
  }

  void _onEventChanged() {
    if (mounted) _load();
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
    EventChangeNotifier.instance.notify();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Removed from saved', style: const TextStyle(fontFamily: 'Outfit')),
        action: SnackBarAction(label: 'Undo', textColor: _brandColor, onPressed: () async {
          await ApiService.saveEventBookmark(ev.id, _userId!);
          setState(() => _events.insert(0, ev));
          EventChangeNotifier.instance.notify();
        }),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator(color: _brandColor));
    } else if (_events.isEmpty) {
      body = _emptyState();
    } else {
      body = RefreshIndicator(
        color: _brandColor,
        backgroundColor: Colors.white,
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: _events.length,
          itemBuilder: (ctx, i) => _SavedEventCard(
            event: _events[i],
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EventDetailPage(eventId: _events[i].id)));
              if (mounted) _load();
            },
            onUnsave: () => _unsave(_events[i]),
          ),
        ),
      );
    }

    if (widget.embedded) {
      return Container(color: _bgColor, child: body);
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _secondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Saved Events', style: TextStyle(
            fontFamily: 'Outfit', fontSize: 20,
            fontWeight: FontWeight.bold, color: _secondary)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bookmark_rounded, color: _brandColor, size: 20),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _brandColor.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.bookmark_outline, size: 64, color: _brandColor),
    ),
    const SizedBox(height: 24),
    const Text('No saved events yet', style: TextStyle(
        fontFamily: 'Outfit', fontSize: 20,
        fontWeight: FontWeight.bold, color: _secondary)),
    const SizedBox(height: 8),
    Text('Bookmark events to find them here', style: TextStyle(
        fontFamily: 'Outfit', fontSize: 14, color: Colors.grey.shade500)),
    const SizedBox(height: 28),
    ElevatedButton.icon(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EventDiscoveryPage())),
      icon: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
      label: const Text('Discover Events', style: TextStyle(
          fontFamily: 'Outfit', color: Colors.white, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _brandColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      ),
    ),
  ]));
}

// ─── Premium Saved Event Card ────────────────────────────────────────────────

class _SavedEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback onUnsave;

  const _SavedEventCard({
    required this.event,
    required this.onTap,
    required this.onUnsave,
  });

  String _formatDate(DateTime dt) =>
      DateFormat('EEE, d MMM yyyy • h:mm a').format(dt);

  String _petEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'bird': return '🦜';
      case 'rabbit': return '🐇';
      case 'fish': return '🐟';
      default: return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover image ──────────────────────────────────
              _buildCover(),
              // ── Details ──────────────────────────────────────
              _buildDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image / placeholder
          event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty
              ? Image.network(event.coverImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _coverPlaceholder())
              : _coverPlaceholder(),

          // Gradient overlay
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xBB000000)],
              stops: [0.3, 1.0],
            ),
          )),

          // Status badge top-left
          Positioned(
            top: 12, left: 12,
            child: EventStatusBadge(status: event.status),
          ),

          // Unsave button top-right
          Positioned(
            top: 8, right: 8,
            child: _UnsaveButton(onTap: onUnsave),
          ),

          // Title bottom-left
          Positioned(
            left: 14, right: 50, bottom: 12,
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Outfit', color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.bold,
                height: 1.2,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandColor, Color(0xFF1A5276)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: const Center(child: Icon(Icons.event_rounded,
          color: Colors.white30, size: 52)),
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(children: [
            const Icon(Icons.schedule_rounded, size: 14, color: _brandColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(_formatDate(event.startDatetime),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                      color: Colors.grey.shade600)),
            ),
          ]),
          const SizedBox(height: 6),
          // Location row
          Row(children: [
            const Icon(Icons.location_on_rounded, size: 14, color: _brandColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                event.location.isNotEmpty ? event.location : 'Location TBA',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    color: Colors.grey.shade600),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Footer: pet chip + stats
          Row(children: [
            // Pet type
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _brandColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _brandColor.withValues(alpha: 0.25)),
              ),
              child: Text('${_petEmoji(event.petType)} ${event.petType}',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 11,
                    color: _brandColor, fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            // Going count
            const Icon(Icons.check_circle_outline_rounded,
                size: 14, color: Color(0xFF27AE60)),
            const SizedBox(width: 3),
            Text('${event.goingCount}',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            // Interested count
            const Icon(Icons.star_outline_rounded,
                size: 14, color: Color(0xFFF39C12)),
            const SizedBox(width: 3),
            Text('${event.interestedCount}',
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 12,
                    color: Color(0xFFF39C12), fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

// ─── Animated unsave button ──────────────────────────────────────────────────

class _UnsaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UnsaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 0.8),
        ),
        child: const Icon(Icons.bookmark_remove_rounded,
            color: _brandColor, size: 20),
      ),
    );
  }
}
