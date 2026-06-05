import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../widgets/event_status_badge.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'event_discussion_page.dart';
import 'edit_event_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

class EventDetailPage extends StatefulWidget {
  final int eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  EventModel? _event;
  bool _isLoading = true;
  String? _participationStatus; // 'interested' | 'going' | null
  bool _isSaved = false;
  int? _currentUserId;
  List<dynamic> _commentsPreview = [];
  List<dynamic> _gallery = [];
  List<dynamic> _participants = [];
  bool _descExpanded = false;
  bool _joiningBusy = false;
  bool _saveBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = await AuthService.getUserId();
    if (!mounted) return;
    setState(() => _currentUserId = uid);

    final results = await Future.wait([
      ApiService.getEventById(widget.eventId),
      if (uid != null) ApiService.getEventParticipationStatus(widget.eventId, uid),
      if (uid != null) ApiService.isEventSaved(widget.eventId, uid),
      ApiService.getEventComments(widget.eventId),
      ApiService.getEventGallery(widget.eventId),
      ApiService.getEventParticipants(widget.eventId),
    ]);

    if (!mounted) return;
    final eventRes = results[0];
    EventModel? ev;
    if (eventRes['success'] == true && eventRes['data'] != null) {
      final raw = eventRes['data'];
      // data might be the event map directly, or double-wrapped {success, data: {...}}
      final Map<String, dynamic>? evMap = raw is Map<String, dynamic>
          ? (raw.containsKey('id') ? raw : raw['data'] as Map<String, dynamic>?)
          : null;
      if (evMap != null) ev = EventModel.fromJson(evMap);
    }

    String? partStatus;
    bool saved = false;
    if (uid != null) {
      final pRes = results[1];
      if (pRes['success'] == true && pRes['data'] != null) {
        partStatus = pRes['data']['status'] as String?;
      }
      final sRes = results[2];
      if (sRes['success'] == true && sRes['data'] != null) {
        saved = sRes['data']['isSaved'] == true;
      }
    }

    final commentsRes = uid != null ? results[3] : results[1];
    List<dynamic> comments = [];
    if (commentsRes['success'] == true) {
      final raw = commentsRes['data'];
      final List? rawList = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) comments = rawList.take(3).toList();
    }

    final galleryRes = uid != null ? results[4] : results[2];
    List<dynamic> gallery = [];
    if (galleryRes['success'] == true) {
      final raw = galleryRes['data'];
      final List? rawList = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) gallery = rawList;
    }

    final participantsRes = uid != null ? results[5] : results[3];
    List<dynamic> participants = [];
    if (participantsRes['success'] == true) {
      final raw = participantsRes['data'];
      final List? rawList = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) participants = rawList;
    }

    setState(() {
      _event = ev;
      _participationStatus = partStatus;
      _isSaved = saved;
      _commentsPreview = comments;
      _gallery = gallery;
      _participants = participants;
      _isLoading = false;
    });
  }

  Future<void> _handleParticipate(String targetStatus) async {
    if (_joiningBusy || _currentUserId == null || _event == null) return;
    setState(() => _joiningBusy = true);

    final ev = _event!;
    final uid = _currentUserId!;

    if (_participationStatus == targetStatus) {
      // Leave
      await ApiService.leaveEvent(ev.id, uid);
      setState(() {
        if (targetStatus == 'going') {
          _event = ev.copyWith(goingCount: (ev.goingCount - 1).clamp(0, 99999));
        } else {
          _event = ev.copyWith(interestedCount: (ev.interestedCount - 1).clamp(0, 99999));
        }
        _participationStatus = null;
      });
    } else {
      if (_participationStatus != null) {
        // Switch: leave first
        await ApiService.leaveEvent(ev.id, uid);
        final oldField = _participationStatus == 'going' ? 'going' : 'interested';
        final updatedEv = oldField == 'going'
            ? ev.copyWith(goingCount: (ev.goingCount - 1).clamp(0, 99999))
            : ev.copyWith(interestedCount: (ev.interestedCount - 1).clamp(0, 99999));
        _event = updatedEv;
      }
      final res = await ApiService.joinEvent(ev.id, uid, targetStatus);
      if (res['success'] == true) {
        setState(() {
          _participationStatus = targetStatus;
          if (targetStatus == 'going') {
            _event = _event!.copyWith(goingCount: _event!.goingCount + 1);
          } else {
            _event = _event!.copyWith(interestedCount: _event!.interestedCount + 1);
          }
        });
      }
    }
    if (mounted) setState(() => _joiningBusy = false);
  }

  Future<void> _toggleSave() async {
    if (_saveBusy || _currentUserId == null || _event == null) return;
    setState(() => _saveBusy = true);
    if (_isSaved) {
      await ApiService.unsaveEventBookmark(_event!.id, _currentUserId!);
    } else {
      await ApiService.saveEventBookmark(_event!.id, _currentUserId!);
    }
    if (mounted) setState(() { _isSaved = !_isSaved; _saveBusy = false; });
  }

  bool get _isOrganizer =>
      _currentUserId != null && _event != null && _event!.userId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _brandColor)),
      );
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
        body: const Center(child: Text('Event not found', style: TextStyle(fontFamily: 'Outfit'))),
      );
    }

    final ev = _event!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(ev),
          SliverToBoxAdapter(child: _buildContent(ev)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(ev),
    );
  }

  Widget _buildSliverAppBar(EventModel ev) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            child: IconButton(
              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: Colors.white, size: 20),
              onPressed: _toggleSave,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(ev.title,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14,
                fontWeight: FontWeight.bold, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        background: Stack(fit: StackFit.expand, children: [
          ev.coverImageUrl != null && ev.coverImageUrl!.isNotEmpty
              ? Image.network(ev.coverImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverPlaceholder())
              : _coverPlaceholder(),
          // Gradient overlay
          const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54]))),
        ]),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_brandColor, Color(0xFF1A5276)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: const Center(child: Icon(Icons.event, size: 80, color: Colors.white54)));
  }

  Widget _buildContent(EventModel ev) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildStatusAndCategory(ev),
      _buildOrganizerRow(ev),
      _buildDateCard(ev),
      _buildLocationCard(ev),
      _buildStatsRow(ev),
      _buildActionButtons(ev),
      _buildDescriptionCard(ev),
      if (_gallery.isNotEmpty) _buildGallerySection(),
      if (_participants.isNotEmpty) _buildParticipantsSection(),
      _buildDiscussionPreview(ev),
      if (ev.contactInfo != null && ev.contactInfo!.isNotEmpty) _buildContactCard(ev),
      const SizedBox(height: 100),
    ]);
  }

  Widget _buildStatusAndCategory(EventModel ev) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        EventStatusBadge(status: ev.status),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: _brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(ev.category, style: const TextStyle(fontFamily: 'Outfit',
              color: _brandColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        if (ev.petType.isNotEmpty && ev.petType != 'All') ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('🐾 ${ev.petType}', style: const TextStyle(fontFamily: 'Outfit',
                color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  Widget _buildOrganizerRow(EventModel ev) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        CircleAvatar(radius: 20, backgroundColor: _brandColor.withValues(alpha: 0.2),
          backgroundImage: ev.organizerAvatarUrl != null && ev.organizerAvatarUrl!.isNotEmpty
              ? NetworkImage(ev.organizerAvatarUrl!) : null,
          child: ev.organizerAvatarUrl == null || ev.organizerAvatarUrl!.isEmpty
              ? const Icon(Icons.person, color: _brandColor) : null),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Organized by', style: TextStyle(fontFamily: 'Outfit',
              fontSize: 11, color: Colors.grey.shade500)),
          Text(ev.organizerName ?? 'Unknown', style: const TextStyle(fontFamily: 'Outfit',
              fontSize: 15, fontWeight: FontWeight.bold, color: _secondary)),
        ])),
        if (_isOrganizer)
          TextButton.icon(
            onPressed: () async {
              final updated = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditEventPage(event: ev)));
              if (updated == true && mounted) _load();
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit', style: TextStyle(fontFamily: 'Outfit')),
            style: TextButton.styleFrom(foregroundColor: _brandColor),
          ),
      ]),
    );
  }

  Widget _buildDateCard(EventModel ev) {
    final fmt = DateFormat('EEE, d MMM yyyy • h:mm a');
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.calendar_today_outlined, color: _brandColor, size: 20),
        const SizedBox(width: 10),
        const Text('Date & Time', style: TextStyle(fontFamily: 'Outfit',
            fontWeight: FontWeight.bold, color: _secondary)),
      ]),
      const SizedBox(height: 8),
      Text(fmt.format(ev.startDatetime), style: const TextStyle(fontFamily: 'Outfit', fontSize: 14)),
      if (ev.endDatetime != null) ...[
        const SizedBox(height: 4),
        Text('Ends: ${fmt.format(ev.endDatetime!)}',
            style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey.shade600)),
      ],
    ]));
  }

  Widget _buildLocationCard(EventModel ev) {
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.location_on_outlined, color: _brandColor, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(ev.location.isNotEmpty ? ev.location : 'Location TBA',
            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, color: _secondary))),
      ]),
      if (ev.latitude != null && ev.longitude != null) ...[
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(
                  initialCenter: LatLng(ev.latitude!, ev.longitude!),
                  initialZoom: 14),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: [
                  Marker(
                      point: LatLng(ev.latitude!, ev.longitude!),
                      child: const Icon(Icons.location_pin, color: _brandColor, size: 36))
                ]),
              ],
            ),
          ),
        ),
      ],
    ]));
  }

  Widget _buildStatsRow(EventModel ev) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Expanded(child: _statCard('✅ Going', ev.goingCount, const Color(0xFF27AE60))),
        const SizedBox(width: 12),
        Expanded(child: _statCard('⭐ Interested', ev.interestedCount, _brandColor)),
        if (ev.maxParticipants > 0) ...[
          const SizedBox(width: 12),
          Expanded(child: _statCard('👤 Max', ev.maxParticipants, const Color(0xFF8E44AD))),
        ],
      ]),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text('$count', style: TextStyle(fontFamily: 'Outfit', fontSize: 22,
            fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 11,
            color: color.withValues(alpha: 0.8))),
      ]),
    );
  }

  Widget _buildActionButtons(EventModel ev) {
    if (_isOrganizer || ev.status == 'completed' || ev.status == 'cancelled') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Expanded(child: _participateButton('Interested', Icons.star_outline,
            Icons.star, const Color(0xFF2980B9), 'interested')),
        const SizedBox(width: 12),
        Expanded(child: _participateButton('Going', Icons.check_circle_outline,
            Icons.check_circle, const Color(0xFF27AE60), 'going')),
      ]),
    );
  }

  Widget _participateButton(String label, IconData outline, IconData filled,
      Color color, String status) {
    final isActive = _participationStatus == status;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: color.withValues(alpha: 0.3),
              blurRadius: 8, offset: const Offset(0, 3))] : []),
      child: Material(color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _joiningBusy ? null : () => _handleParticipate(status),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isActive ? filled : outline, color: isActive ? Colors.white : color, size: 18),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600, color: isActive ? Colors.white : color)),
              ]),
            ),
          )),
    );
  }

  Widget _buildDescriptionCard(EventModel ev) {
    if (ev.description.isEmpty) return const SizedBox.shrink();
    const maxLines = 4;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('About This Event', style: TextStyle(fontFamily: 'Outfit',
          fontWeight: FontWeight.bold, fontSize: 16, color: _secondary)),
      const SizedBox(height: 8),
      Text(ev.description,
          style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, height: 1.6),
          maxLines: _descExpanded ? null : maxLines,
          overflow: _descExpanded ? null : TextOverflow.ellipsis),
      TextButton(
        onPressed: () => setState(() => _descExpanded = !_descExpanded),
        style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: _brandColor),
        child: Text(_descExpanded ? 'Show less' : 'Show more',
            style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
      ),
    ]));
  }

  Widget _buildGallerySection() {
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Gallery', style: TextStyle(fontFamily: 'Outfit',
            fontWeight: FontWeight.bold, fontSize: 16, color: _secondary)),
        Text('${_gallery.length} photos', style: TextStyle(fontFamily: 'Outfit',
            color: Colors.grey.shade500, fontSize: 13)),
      ]),
      const SizedBox(height: 12),
      SizedBox(height: 90, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _gallery.length,
        itemBuilder: (ctx, i) {
          final url = _gallery[i]['image_url'] as String? ?? '';
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _showFullImage(url),
              child: Image.network(url, width: 90, height: 90, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 90, height: 90,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey))),
            ),
          );
        },
      )),
    ]));
  }

  void _showFullImage(String url) {
    showDialog(context: context, builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Image.network(url),
      ),
    ));
  }

  Widget _buildParticipantsSection() {
    final shown = _participants.take(8).toList();
    final extra = _participants.length - 8;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Participants', style: TextStyle(fontFamily: 'Outfit',
          fontWeight: FontWeight.bold, fontSize: 16, color: _secondary)),
      const SizedBox(height: 12),
      Row(children: [
        ...shown.map((p) {
          final av = p['avatar_url'] as String? ?? p['profile_picture_url'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(radius: 18, backgroundColor: _brandColor.withValues(alpha: 0.2),
                backgroundImage: av.isNotEmpty ? NetworkImage(av) : null,
                child: av.isEmpty ? const Icon(Icons.person, size: 16, color: _brandColor) : null),
          );
        }),
        if (extra > 0)
          CircleAvatar(radius: 18, backgroundColor: Colors.grey.shade200,
              child: Text('+$extra', style: const TextStyle(fontFamily: 'Outfit',
                  fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
      const SizedBox(height: 8),
      Text('${_event!.goingCount} going · ${_event!.interestedCount} interested',
          style: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade600, fontSize: 13)),
    ]));
  }

  Widget _buildDiscussionPreview(EventModel ev) {
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Discussion', style: TextStyle(fontFamily: 'Outfit',
            fontWeight: FontWeight.bold, fontSize: 16, color: _secondary)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => EventDiscussionPage(eventId: ev.id,
                  eventTitle: ev.title, organizerId: ev.userId))),
          style: TextButton.styleFrom(foregroundColor: _brandColor, padding: EdgeInsets.zero),
          child: const Text('View All', style: TextStyle(fontFamily: 'Outfit',
              fontWeight: FontWeight.w600)),
        ),
      ]),
      if (_commentsPreview.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(12),
          child: Text('No comments yet. Be the first!',
              style: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400))))
      else
        ..._commentsPreview.map((c) => _commentPreviewTile(c)),
    ]));
  }

  Widget _commentPreviewTile(dynamic c) {
    final name = c['author_name'] ?? c['username'] ?? c['display_name'] ?? 'User';
    final text = c['text'] ?? '';
    final av = c['author_avatar_url'] ?? c['profile_picture_url'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 16, backgroundColor: _brandColor.withValues(alpha: 0.2),
            backgroundImage: av.isNotEmpty ? NetworkImage(av) : null,
            child: av.isEmpty ? const Icon(Icons.person, size: 14, color: _brandColor) : null),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontFamily: 'Outfit',
              fontSize: 13, fontWeight: FontWeight.bold, color: _secondary)),
          Text(text, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildContactCard(EventModel ev) {
    return _card(Row(children: [
      const Icon(Icons.contact_phone_outlined, color: _brandColor, size: 20),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Contact', style: TextStyle(fontFamily: 'Outfit',
            fontWeight: FontWeight.bold, color: _secondary)),
        Text(ev.contactInfo!, style: TextStyle(fontFamily: 'Outfit',
            color: Colors.grey.shade700, fontSize: 13)),
      ]),
    ]));
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 3))]),
      child: child,
    );
  }

  Widget? _buildBottomBar(EventModel ev) {
    if (_isOrganizer) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12, offset: const Offset(0, -3))]),
        child: ElevatedButton.icon(
          onPressed: () async {
            final updated = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => EditEventPage(event: ev)));
            if (updated == true && mounted) _load();
          },
          icon: const Icon(Icons.settings, color: Colors.white, size: 18),
          label: const Text('Manage Event', style: TextStyle(fontFamily: 'Outfit',
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: _brandColor, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 52)),
        ),
      );
    }
    if (ev.status != 'upcoming' && ev.status != 'ongoing') return null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12, offset: const Offset(0, -3))]),
      child: Row(children: [
        Expanded(child: _participateButton('Interested', Icons.star_outline,
            Icons.star, const Color(0xFF2980B9), 'interested')),
        const SizedBox(width: 12),
        Expanded(child: _participateButton('Going', Icons.check_circle_outline,
            Icons.check_circle, const Color(0xFF27AE60), 'going')),
      ]),
    );
  }
}
