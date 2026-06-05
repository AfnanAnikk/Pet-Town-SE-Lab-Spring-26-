import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/event_status_badge.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'event_detail_page.dart';
import 'edit_event_page.dart';
import 'create_event_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

class MyEventsPage extends StatefulWidget {
  final bool embedded;
  const MyEventsPage({super.key, this.embedded = false});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<EventModel> _hosting = [];
  List<EventModel> _past = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final uid = await AuthService.getUserId();
    if (!mounted) return;
    setState(() { _userId = uid; _isLoading = true; });
    if (uid == null) { setState(() => _isLoading = false); return; }
    final res = await ApiService.getEventsByUser(uid);
    if (!mounted) return;
    List<EventModel> all = [];
    if (res['success'] == true) {
      final raw = res['data'];
      final List? list = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (list != null) {
        all = list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    setState(() {
      _hosting = all.where((e) => ['upcoming','ongoing','draft'].contains(e.status)).toList();
      _past = all.where((e) => ['completed','cancelled'].contains(e.status)).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteEvent(EventModel ev) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete Event', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
      content: Text('Delete "${ev.title}"? This cannot be undone.',
          style: const TextStyle(fontFamily: 'Outfit')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit'))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete', style: TextStyle(fontFamily: 'Outfit', color: Colors.white))),
      ],
    ));
    if (confirm == true && _userId != null) {
      await ApiService.deleteEvent(ev.id, _userId!);
      _load();
    }
  }

  void _showParticipants(EventModel ev) async {
    final res = await ApiService.getEventParticipants(ev.id);
    if (!mounted) return;
    final List participants = res['data'] is List
        ? res['data'] as List
        : (res['data'] is Map && res['data']['data'] is List
            ? res['data']['data'] as List
            : []);
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          Padding(padding: const EdgeInsets.all(16),
              child: Text('Participants (${participants.length})', style: const TextStyle(
                  fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18, color: _secondary))),
          Expanded(child: participants.isEmpty
              ? const Center(child: Text('No participants yet', style: TextStyle(fontFamily: 'Outfit', color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: participants.length,
                  itemBuilder: (ctx, i) {
                    final p = participants[i];
                    final name = p['name'] ?? p['username'] ?? p['display_name'] ?? 'User';
                    final av = p['avatar_url'] ?? p['profile_picture_url'] ?? '';
                    final status = p['status'] ?? 'interested';
                    final approved = p['approved'] == true;
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: _brandColor.withValues(alpha: 0.2),
                          backgroundImage: av.isNotEmpty ? NetworkImage(av) : null,
                          child: av.isEmpty ? const Icon(Icons.person, color: _brandColor) : null),
                      title: Text(name, style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
                      subtitle: Text(status, style: const TextStyle(fontFamily: 'Outfit')),
                      trailing: !approved
                          ? ElevatedButton(
                              onPressed: () async {
                                await ApiService.approveParticipant(ev.id, p['user_id'] as int, _userId!);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _showParticipants(ev);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: _brandColor, elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                              child: const Text('Approve', style: TextStyle(fontFamily: 'Outfit',
                                  color: Colors.white, fontSize: 12)))
                          : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(status == 'going' ? '✅ Going' : '⭐ Interested',
                                  style: TextStyle(fontFamily: 'Outfit', fontSize: 12,
                                      color: status == 'going' ? Colors.green.shade700 : _brandColor))),
                    );
                  })),
        ]),
      ),
    );
  }

  void _showAnnouncement(EventModel ev) {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📣 Send Announcement', style: TextStyle(fontFamily: 'Outfit',
                fontWeight: FontWeight.bold, fontSize: 18, color: _secondary)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 4,
                style: const TextStyle(fontFamily: 'Outfit'),
                decoration: InputDecoration(hintText: 'Write your announcement…',
                    hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _brandColor, width: 2)))),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty || _userId == null) return;
                await ApiService.sendEventAnnouncement(ev.id, _userId!, ctrl.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Announcement sent! 📣', style: TextStyle(fontFamily: 'Outfit')),
                      backgroundColor: Color(0xFF27AE60)));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _brandColor, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Send', style: TextStyle(fontFamily: 'Outfit',
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            )),
          ]),
        ),
      ),
    );
  }

  void _showStatusPicker(EventModel ev) {
    const statuses = ['upcoming','ongoing','completed','cancelled','draft'];
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Change Status', style: TextStyle(fontFamily: 'Outfit',
              fontWeight: FontWeight.bold, fontSize: 18, color: _secondary)),
          const SizedBox(height: 12),
          ...statuses.map((s) => ListTile(
            leading: EventStatusBadge(status: s),
            title: Text(s[0].toUpperCase() + s.substring(1),
                style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              if (_userId == null) return;
              await ApiService.updateEventStatus(ev.id, s, _userId!);
              _load();
            },
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(children: [
      TabBar(controller: _tab, labelColor: _brandColor, unselectedLabelColor: Colors.grey,
          indicatorColor: _brandColor, indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Hosting'), Tab(text: 'Past')]),
      Expanded(child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : TabBarView(controller: _tab, children: [
              _buildList(_hosting),
              _buildList(_past),
            ])),
    ]);

    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context)),
          title: const Text('My Events', style: TextStyle(fontFamily: 'Outfit',
              fontSize: 20, fontWeight: FontWeight.bold, color: _brandColor))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventPage()));
          if (r == true && mounted) _load();
        },
        backgroundColor: _brandColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create', style: TextStyle(fontFamily: 'Outfit', color: Colors.white)),
      ),
      body: content,
    );
  }

  Widget _buildList(List<EventModel> events) {
    if (events.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_note, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No events here', style: TextStyle(fontFamily: 'Outfit',
            fontSize: 16, color: Colors.grey.shade500)),
      ]));
    }
    return RefreshIndicator(color: _brandColor, onRefresh: _load,
      child: ListView.builder(padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (ctx, i) => _eventManagementCard(events[i]),
      ),
    );
  }

  Widget _eventManagementCard(EventModel ev) {
    final fmt = DateFormat('d MMM yyyy, h:mm a');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => EventDetailPage(eventId: ev.id))),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Thumbnail
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 72, height: 72,
                child: ev.coverImageUrl != null && ev.coverImageUrl!.isNotEmpty
                    ? Image.network(ev.coverImageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _coverFallback())
                    : _coverFallback())),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ev.title, style: const TextStyle(fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold, fontSize: 15, color: _secondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(fmt.format(ev.startDatetime), style: TextStyle(fontFamily: 'Outfit',
                  fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Row(children: [
                EventStatusBadge(status: ev.status),
                const SizedBox(width: 8),
                Text('${ev.goingCount} going',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ])),
          ]),
          const SizedBox(height: 10),
          // Action buttons
          Row(children: [
            _actionBtn(Icons.edit_outlined, 'Edit', () async {
              final r = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditEventPage(event: ev)));
              if (r == true && mounted) _load();
            }),
            _actionBtn(Icons.delete_outline, 'Delete', () => _deleteEvent(ev), color: Colors.red),
            _actionBtn(Icons.people_outline, 'People', () => _showParticipants(ev)),
            _actionBtn(Icons.campaign_outlined, 'Announce', () => _showAnnouncement(ev)),
            _actionBtn(Icons.swap_horiz, 'Status', () => _showStatusPicker(ev)),
          ]),
        ])),
      ),
    );
  }

  Widget _coverFallback() => Container(color: _brandColor.withValues(alpha: 0.15),
      child: const Icon(Icons.event, color: _brandColor, size: 32));

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) =>
      Expanded(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child:
          Column(children: [
            Icon(icon, size: 20, color: color ?? _brandColor),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontFamily: 'Outfit', fontSize: 10,
                color: color ?? _brandColor, fontWeight: FontWeight.w600)),
          ]))));
}
