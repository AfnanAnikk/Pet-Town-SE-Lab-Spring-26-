import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'event_detail_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

class EventInvitationsPage extends StatefulWidget {
  final bool embedded;
  const EventInvitationsPage({super.key, this.embedded = false});

  @override
  State<EventInvitationsPage> createState() => _EventInvitationsPageState();
}

class _EventInvitationsPageState extends State<EventInvitationsPage> {
  List<EventInvitationModel> _invitations = [];
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

    final res = await ApiService.getMyEventInvitations(uid);
    if (!mounted) return;
    List<EventInvitationModel> list = [];
    if (res['success'] == true) {
      final raw = res['data'];
      final List? rawList = raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) {
        list = rawList
            .map((e) => EventInvitationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    setState(() { _invitations = list; _isLoading = false; });
  }

  Future<void> _respond(EventInvitationModel inv, String status) async {
    await ApiService.respondEventInvitation(inv.id, status);
    final idx = _invitations.indexWhere((i) => i.id == inv.id);
    if (idx != -1 && mounted) {
      final updated = EventInvitationModel(
        id: inv.id, eventId: inv.eventId, eventTitle: inv.eventTitle,
        eventCoverUrl: inv.eventCoverUrl, eventStartDatetime: inv.eventStartDatetime,
        inviterName: inv.inviterName, inviterAvatarUrl: inv.inviterAvatarUrl,
        status: status, createdAt: inv.createdAt,
      );
      setState(() => _invitations[idx] = updated);
    }
    if (status == 'accepted' && _userId != null) {
      await ApiService.joinEvent(inv.eventId, _userId!, 'going');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are now going to "${inv.eventTitle}"! 🎉',
              style: const TextStyle(fontFamily: 'Outfit')),
              backgroundColor: const Color(0xFF27AE60)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator(color: _brandColor))
        : _invitations.isEmpty
            ? _emptyState()
            : RefreshIndicator(
                color: _brandColor, onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _invitations.length,
                  itemBuilder: (ctx, i) => _invitationCard(_invitations[i]),
                ),
              );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Event Invitations', style: TextStyle(fontFamily: 'Outfit',
            fontSize: 20, fontWeight: FontWeight.bold, color: _brandColor)),
      ),
      body: body,
    );
  }

  Widget _invitationCard(EventInvitationModel inv) {
    final fmt = DateFormat('d MMM yyyy');
    final isPending = inv.status == 'pending';

    Color statusColor;
    String statusLabel;
    switch (inv.status) {
      case 'accepted': statusColor = const Color(0xFF27AE60); statusLabel = '✅ Accepted'; break;
      case 'declined': statusColor = Colors.red; statusLabel = '❌ Declined'; break;
      default: statusColor = _brandColor; statusLabel = '⏳ Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => EventDetailPage(eventId: inv.eventId))),
        child: Padding(padding: const EdgeInsets.all(14), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Event thumbnail
              ClipRRect(borderRadius: BorderRadius.circular(10),
                child: SizedBox(width: 72, height: 72,
                  child: inv.eventCoverUrl != null && inv.eventCoverUrl!.isNotEmpty
                      ? Image.network(inv.eventCoverUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumb())
                      : _thumb())),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv.eventTitle, style: const TextStyle(fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold, fontSize: 15, color: _secondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('📅 ${fmt.format(inv.eventStartDatetime)}',
                    style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Row(children: [
                  if (inv.inviterAvatarUrl != null && inv.inviterAvatarUrl!.isNotEmpty)
                    CircleAvatar(radius: 10, backgroundImage: NetworkImage(inv.inviterAvatarUrl!)),
                  const SizedBox(width: 5),
                  Expanded(child: Text('Invited by ${inv.inviterName}',
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ])),
            ]),
            const SizedBox(height: 12),
            if (isPending) Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _respond(inv, 'declined'),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: const Text('Decline', style: TextStyle(fontFamily: 'Outfit',
                    color: Colors.red, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => _respond(inv, 'accepted'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60),
                    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
                child: const Text('Accept', style: TextStyle(fontFamily: 'Outfit',
                    color: Colors.white, fontWeight: FontWeight.w600)),
              )),
            ])
            else Align(alignment: Alignment.centerRight,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: TextStyle(fontFamily: 'Outfit',
                    color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)))),
          ],
        ),
      ),
    ),
  );
  }

  Widget _thumb() => Container(color: _brandColor.withValues(alpha: 0.15),
      child: const Icon(Icons.event, color: _brandColor));

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('✉️', style: TextStyle(fontSize: 64)),
    const SizedBox(height: 16),
    Text('No invitations yet', style: TextStyle(fontFamily: 'Outfit',
        fontSize: 17, color: Colors.grey.shade500)),
    const SizedBox(height: 8),
    Text('When friends invite you to events, they\'ll appear here',
        style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: Colors.grey.shade400),
        textAlign: TextAlign.center),
  ]));
}
