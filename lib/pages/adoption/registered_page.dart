import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../messaging/chat_page.dart';

class RegisteredPage extends StatefulWidget {
  const RegisteredPage({super.key});

  @override
  State<RegisteredPage> createState() => _RegisteredPageState();
}

class _RegisteredPageState extends State<RegisteredPage> {
  bool _isLoading = true;
  List<dynamic> _myRequests = [];
  List<dynamic> _ownerRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchAllRequests();
  }

  Future<void> _fetchAllRequests() async {
    final userId = await AuthService.getUserId();

    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final bookedRes = await ApiService.getUserAdoptionRequests(userId);
    final ownerRes = await ApiService.getOwnerAdoptionRequests(userId);

    if (!mounted) return;

    setState(() {
      _myRequests = bookedRes['success'] == true && bookedRes['data'] != null
          ? bookedRes['data']
          : [];

      _ownerRequests = ownerRes['success'] == true && ownerRes['data'] != null
          ? ownerRes['data']
          : [];

      _isLoading = false;
    });
  }

  void _openChat({
    required int userId,
    required String name,
    required String image,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          otherUserId: userId,
          otherUserName: name,
          otherUserImage: image,
        ),
      ),
    );
  }

  Future<void> _updateRequestStatus(dynamic requestIdRaw, String status) async {
    final requestId = requestIdRaw is int
        ? requestIdRaw
        : int.tryParse(requestIdRaw?.toString() ?? '');

    if (requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid request ID')),
      );
      return;
    }

    final res = await ApiService.updateAdoptionRequestStatus(requestId, status);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['success'] == true
              ? 'Request $status successfully'
              : res['message'] ?? 'Failed to update request',
        ),
      ),
    );

    if (res['success'] == true) {
      _fetchAllRequests();
    }
  }

  void _showBookedPetModal(dynamic request) {
    final ownerId = int.tryParse(request['owner_user_id'].toString());
    final ownerName = request['owner_username'] ?? request['owner_name'] ?? 'Owner';
    final ownerImage = request['owner_profile_picture_url']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _detailsSheet(
          title: request['pet_name'] ?? 'Pet Details',
          imageUrl: request['image_url'],
          mainName: ownerName,
          mainImage: ownerImage,
          roleText: 'Owner',
          details: [
            ['Pet', request['pet_name']],
            ['Breed', request['pet_breed']],
            ['Age', request['pet_age']],
            ['Status', request['request_status']],
            ['Owner Contact', request['owner_contact']],
          ],
          buttonText: 'Message Owner',
          onMessage: ownerId == null
              ? null
              : () => _openChat(
                    userId: ownerId,
                    name: ownerName,
                    image: ownerImage,
                  ),
        );
      },
    );
  }

  void _showRehomeRequestModal(dynamic request) {
    final requesterId = int.tryParse(request['requester_user_id'].toString());
    final requesterName =
        request['requester_username'] ?? request['requester_name'] ?? 'Requester';
    final requesterImage =
        request['requester_profile_picture_url']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _detailsSheet(
          title: request['pet_name'] ?? 'Request Details',
          imageUrl: request['image_url'],
          mainName: requesterName,
          mainImage: requesterImage,
          roleText: 'Requester',
          details: [
            ['Pet', request['pet_name']],
            ['Requester Name', request['requester_name']],
            ['Phone', request['requester_phone']],
            ['Address', request['requester_address']],
            ['Pickup Date', request['pickup_date']],
            ['Status', request['request_status']],
          ],
          buttonText: 'Message Requester',
          onMessage: requesterId == null
              ? null
              : () => _openChat(
                    userId: requesterId,
                    name: requesterName,
                    image: requesterImage,
                  ),
          extraActions: request['request_status'] == 'pending'
            ? Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateRequestStatus(request['request_id'], 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateRequestStatus(request['request_id'], 'accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
            : null,
        );
      },
    );
  }

  Widget _detailsSheet({
    required String title,
    required String? imageUrl,
    required String mainName,
    required String mainImage,
    required String roleText,
    required List<List<dynamic>> details,
    required String buttonText,
    required VoidCallback? onMessage,
    Widget? extraActions,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                imageUrl ?? '',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 170,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.pets, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: mainImage.isNotEmpty ? NetworkImage(mainImage) : null,
                  child: mainImage.isEmpty
                      ? Text(
                          mainName.isNotEmpty ? mainName[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF374957),
                          )),
                      Text('$mainName • $roleText',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: const Color(0xFF3293B3),
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...details.map((d) => _detailRow(d[0].toString(), d[1]?.toString() ?? '')),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMessage == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        onMessage();
                      },
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3293B3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (extraActions != null) ...[
              const SizedBox(height: 12),
              extraActions,
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF374957),
              )),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              indicatorColor: const Color(0xFF3293B3),
              labelColor: const Color(0xFF3293B3),
              unselectedLabelColor: Colors.black54,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Booked Pets'),
                Tab(text: 'My Re-Homes'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3293B3)))
                : TabBarView(
                    children: [
                      _buildList(
                        items: _myRequests,
                        emptyText: "You haven't booked any pets yet.",
                        onTap: _showBookedPetModal,
                      ),
                      _buildList(
                        items: _ownerRequests,
                        emptyText: "No one has requested your re-homed pets yet.",
                        onTap: _showRehomeRequestModal,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<dynamic> items,
    required String emptyText,
    required Function(dynamic) onTap,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText, style: GoogleFonts.outfit(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final request = items[index];

          return GestureDetector(
            onTap: () => onTap(request),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      request['image_url'] ?? '',
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 78,
                        height: 78,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.pets, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request['pet_name'] ?? 'Unknown Pet',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF374957),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request['pet_age'] ?? ''} • ${request['pet_breed'] ?? ''}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _statusChip(request['request_status'] ?? 'pending'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3293B3),
        ),
      ),
    );
  }
}