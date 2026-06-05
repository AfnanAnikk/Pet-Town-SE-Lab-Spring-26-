import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/event_notifier.dart';
import 'event_detail_page.dart';
import 'create_event_page.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);
const _bgColor = Color(0xFFF5F7FA);

class EventInvitationsPage extends StatefulWidget {
  final bool embedded;
  const EventInvitationsPage({super.key, this.embedded = false});

  @override
  State<EventInvitationsPage> createState() => _EventInvitationsPageState();
}

class _EventInvitationsPageState extends State<EventInvitationsPage> {
  // Received tab variables
  List<EventInvitationModel> _invitations = [];
  bool _isLoadingReceived = true;
  int? _userId;

  // Send tab variables
  List<EventModel> _myEvents = [];
  EventModel? _selectedEvent;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<EventParticipantModel> _selectedEventParticipants = [];
  List<Map<String, dynamic>> _selectedEventInvitations = [];
  bool _isLoadingSendTab = false;
  String _userSearchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    EventChangeNotifier.instance.addListener(_onEventChanged);
  }

  @override
  void dispose() {
    EventChangeNotifier.instance.removeListener(_onEventChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onEventChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final uid = await AuthService.getUserId();
    if (!mounted) return;
    setState(() {
      _userId = uid;
      _isLoadingReceived = true;
    });
    if (uid == null) {
      setState(() => _isLoadingReceived = false);
      return;
    }

    // Fetch received invitations
    final res = await ApiService.getMyEventInvitations(uid);
    if (!mounted) return;
    List<EventInvitationModel> list = [];
    if (res['success'] == true) {
      final raw = res['data'];
      final List? rawList =
          raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) {
        list = rawList
            .map((e) => EventInvitationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    setState(() {
      _invitations = list;
      _isLoadingReceived = false;
    });

    // Load send tab data
    _loadSendTabData();
  }

  Future<void> _loadSendTabData() async {
    if (_userId == null) return;
    setState(() => _isLoadingSendTab = true);

    try {
      // 1. Load my events
      final eventsRes = await ApiService.getEventsByUser(_userId!);
      List<EventModel> myEventsList = [];
      if (eventsRes['success'] == true) {
        final raw = eventsRes['data'];
        final List? rawList =
            raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
        if (rawList != null) {
          myEventsList = rawList
              .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      final usersRes = await ApiService.getAllUsers();
      List<Map<String, dynamic>> usersList = [];
      if (usersRes['success'] == true && usersRes['data'] is List) {
        usersList = List<Map<String, dynamic>>.from(usersRes['data']);
      }


      if (mounted) {
        setState(() {
          _myEvents = myEventsList;
          _allUsers = usersList.where((u) => u['id'] != _userId).toList();
          _filteredUsers = _allUsers;
          if (_myEvents.isNotEmpty && _selectedEvent == null) {
            _selectedEvent = _myEvents.first;
          }
        });
      }

      // 3. Load details for the selected event
      if (_selectedEvent != null) {
        await _loadSelectedEventDetails(_selectedEvent!.id);
      }
    } catch (e) {
      debugPrint("Error loading send tab data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingSendTab = false);
      }
    }
  }

  Future<void> _loadSelectedEventDetails(int eventId) async {
    try {
      // Fetch participants
      final partRes = await ApiService.getEventParticipants(eventId);
      List<EventParticipantModel> participants = [];
      if (partRes['success'] == true) {
        final raw = partRes['data'];
        final List? rawList =
            raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
        if (rawList != null) {
          participants = rawList
              .map((e) => EventParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      // Fetch invitations
      final invRes = await ApiService.getEventInvitations(eventId);
      List<Map<String, dynamic>> invitations = [];
      if (invRes['success'] == true) {
        final raw = invRes['data'];
        final List? rawList =
            raw is List ? raw : (raw is Map ? raw['data'] as List? : null);
        if (rawList != null) {
          invitations = List<Map<String, dynamic>>.from(rawList);
        }
      }

      if (mounted) {
        setState(() {
          _selectedEventParticipants = participants;
          _selectedEventInvitations = invitations;
        });
      }
    } catch (e) {
      debugPrint("Error loading selected event details: $e");
    }
  }

  Future<void> _respond(EventInvitationModel inv, String status) async {
    await ApiService.respondEventInvitation(inv.id, status);
    final idx = _invitations.indexWhere((i) => i.id == inv.id);
    if (idx != -1 && mounted) {
      final updated = EventInvitationModel(
        id: inv.id,
        eventId: inv.eventId,
        eventTitle: inv.eventTitle,
        eventCoverUrl: inv.eventCoverUrl,
        eventStartDatetime: inv.eventStartDatetime,
        inviterName: inv.inviterName,
        inviterAvatarUrl: inv.inviterAvatarUrl,
        status: status,
        createdAt: inv.createdAt,
      );
      setState(() => _invitations[idx] = updated);
    }
    if (status == 'accepted' && _userId != null) {
      await ApiService.joinEvent(inv.eventId, _userId!, 'going');
      // Notify other tabs
      EventChangeNotifier.instance.notify();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are now going to "${inv.eventTitle}"! 🎉',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _inviteUser(int inviteeId, String inviteeName) async {
    if (_selectedEvent == null || _userId == null) return;

    final res = await ApiService.sendEventInvitation(
      _selectedEvent!.id,
      _userId!,
      inviteeId,
    );

    if (res['success'] == true || res['message'] == 'Invitation sent') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invitation sent to $inviteeName! ✉️',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: _brandColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadSelectedEventDetails(_selectedEvent!.id);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ?? 'Failed to send invitation',
              style: const TextStyle(fontFamily: 'Outfit'),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _userSearchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final username = (user['username'] as String? ?? '').toLowerCase();
          final displayName = (user['display_name'] as String? ?? '').toLowerCase();
          final email = (user['email'] as String? ?? '').toLowerCase();
          final q = query.toLowerCase();
          return username.contains(q) || displayName.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _invitations.where((inv) => inv.status == 'pending').length;

    final tabContent = DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: _brandColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _brandColor,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Received'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Send Invites'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: _bgColor,
              child: TabBarView(
                children: [
                  _buildReceivedTab(),
                  _buildSendTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return tabContent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event Invitations',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _brandColor,
          ),
        ),
      ),
      body: tabContent,
    );
  }

  Widget _buildReceivedTab() {
    if (_isLoadingReceived) {
      return const Center(child: CircularProgressIndicator(color: _brandColor));
    }
    if (_invitations.isEmpty) {
      return _emptyState();
    }
    return RefreshIndicator(
      color: _brandColor,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invitations.length,
        itemBuilder: (ctx, i) => _invitationCard(_invitations[i]),
      ),
    );
  }

  Widget _buildSendTab() {
    if (_isLoadingSendTab) {
      return const Center(child: CircularProgressIndicator(color: _brandColor));
    }
    if (_myEvents.isEmpty) {
      return _sendEmptyState();
    }

    return RefreshIndicator(
      color: _brandColor,
      onRefresh: _loadSendTabData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Event selector
          const Text(
            'Select Event to Invite To',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EventModel>(
                value: _selectedEvent,
                isExpanded: true,
                hint: const Text('Select Event', style: TextStyle(fontFamily: 'Outfit')),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: _secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                items: _myEvents.map((e) {
                  return DropdownMenuItem<EventModel>(
                    value: e,
                    child: Text(e.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedEvent = val;
                    });
                    _loadSelectedEventDetails(val.id);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: _filterUsers,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search users by name/email...',
              hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: _userSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filterUsers('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _brandColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Users to Invite',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _secondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_filteredUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _userSearchQuery.isEmpty
                      ? 'No other users found'
                      : 'No users found matching query',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ..._filteredUsers.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final userId = (user['id'] as num).toInt();
    final username = user['username'] as String? ?? 'User';
    final displayName = user['display_name'] as String? ?? username;
    final avatarUrl = user['profile_picture_url'] as String? ?? '';
    final role = user['role'] as String? ?? 'Member';

    // Check participation status
    final isParticipant = _selectedEventParticipants.any((p) => p.userId == userId);
    final participant = isParticipant
        ? _selectedEventParticipants.firstWhere((p) => p.userId == userId)
        : null;

    // Check invitation status
    final isInvited =
        _selectedEventInvitations.any((i) => (i['invitee_id'] as num).toInt() == userId);
    final invitation = isInvited
        ? _selectedEventInvitations
            .firstWhere((i) => (i['invitee_id'] as num).toInt() == userId)
        : null;

    Widget actionWidget;
    if (isParticipant && participant != null) {
      final status = participant.status;
      final String label = status == 'going' ? 'Going' : 'Interested';
      final Color color =
          status == 'going' ? const Color(0xFF27AE60) : const Color(0xFFF39C12);

      actionWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (isInvited && invitation != null) {
      final status = invitation['status'] as String? ?? 'pending';
      final String label = status == 'pending' ? 'Pending' : status.toUpperCase();
      final Color color = status == 'declined' ? Colors.red : _brandColor;

      actionWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      actionWidget = SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: () => _inviteUser(userId, displayName),
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'Invite',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _brandColor.withOpacity(0.1),
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 20, color: _brandColor)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username • $role',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          actionWidget,
        ],
      ),
    );
  }

  Widget _invitationCard(EventInvitationModel inv) {
    final fmt = DateFormat('d MMM yyyy');
    final isPending = inv.status == 'pending';

    Color statusColor;
    String statusLabel;
    switch (inv.status) {
      case 'accepted':
        statusColor = const Color(0xFF27AE60);
        statusLabel = '✅ Accepted';
        break;
      case 'declined':
        statusColor = Colors.red;
        statusLabel = '❌ Declined';
        break;
      default:
        statusColor = _brandColor;
        statusLabel = '⏳ Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailPage(eventId: inv.eventId)),
          );
          if (mounted) _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: inv.eventCoverUrl != null && inv.eventCoverUrl!.isNotEmpty
                          ? Image.network(
                              inv.eventCoverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumb(),
                            )
                          : _thumb(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.eventTitle,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '📅 ${fmt.format(inv.eventStartDatetime)}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (inv.inviterAvatarUrl != null &&
                                inv.inviterAvatarUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(inv.inviterAvatarUrl!),
                              ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Invited by ${inv.inviterName}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respond(inv, 'declined'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respond(inv, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        color: _brandColor.withOpacity(0.15),
        child: const Icon(Icons.event, color: _brandColor),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✉️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No invitations yet',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When friends invite you to events, they\'ll appear here',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _sendEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _brandColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_seat_rounded, size: 52, color: _brandColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Events Created Yet',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You must be the organizer of an event to invite users. Create one now!',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateEventPage()),
                );
                if (result == true) {
                  _load();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'Create Event',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
