import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

const _brandColor = Color(0xFF3293B3);
const _secondary = Color(0xFF374957);

class EventDiscussionPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final int organizerId;

  const EventDiscussionPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.organizerId,
  });

  @override
  State<EventDiscussionPage> createState() => _EventDiscussionPageState();
}

class _EventDiscussionPageState extends State<EventDiscussionPage> {
  List<EventCommentModel> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _currentUserId;
  EventCommentModel? _replyingTo;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = await AuthService.getUserId();
    if (!mounted) return;
    setState(() { _currentUserId = uid; _isLoading = true; });

    final res = await ApiService.getEventComments(widget.eventId);
    if (!mounted) return;
    List<EventCommentModel> list = [];
    if (res['success'] == true) {
      final raw = res['data'];
      // Handle both direct list and double-wrapped {success, data: [...]} responses
      final List? rawList = raw is List
          ? raw
          : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) {
        list = rawList
            .map((e) => EventCommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    setState(() { _comments = list; _isLoading = false; });
  }

  /// Refresh comments without showing the full-page spinner (used after send/react/pin).
  Future<void> _loadSilent() async {
    final res = await ApiService.getEventComments(widget.eventId);
    if (!mounted) return;
    List<EventCommentModel> list = [];
    if (res['success'] == true) {
      final raw = res['data'];
      final List? rawList = raw is List
          ? raw
          : (raw is Map ? raw['data'] as List? : null);
      if (rawList != null) {
        list = rawList
            .map((e) => EventCommentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    if (mounted) setState(() => _comments = list);
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _currentUserId == null || _isSending) return;
    setState(() => _isSending = true);

    final res = await ApiService.addEventComment(
      widget.eventId,
      _currentUserId!,
      text,
      parentId: _replyingTo?.id,
    );

    if (res['success'] == true && mounted) {
      _inputCtrl.clear();
      setState(() { _replyingTo = null; _isSending = false; });
      await _loadSilent();
      // Scroll to bottom after new comment appears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } else {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _react(EventCommentModel comment) async {
    if (_currentUserId == null) return;
    await ApiService.reactToEventComment(comment.id, _currentUserId!);
    _loadSilent();
  }

  Future<void> _pin(EventCommentModel comment) async {
    if (_currentUserId == null) return;
    await ApiService.pinEventComment(comment.id, _currentUserId!);
    _loadSilent();
  }

  bool get _isOrganizer => _currentUserId == widget.organizerId;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Discussion', style: TextStyle(fontFamily: 'Outfit',
              fontSize: 18, fontWeight: FontWeight.bold, color: _secondary)),
          Text(widget.eventTitle, style: TextStyle(fontFamily: 'Outfit',
              fontSize: 12, color: Colors.grey.shade500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: Column(children: [
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _brandColor))
            : _comments.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    color: _brandColor, onRefresh: _load,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _comments.length,
                      itemBuilder: (ctx, i) => _buildCommentTile(_comments[i]),
                    ),
                  )),
        _buildInputBar(),
      ]),
    );
  }

  Widget _buildCommentTile(EventCommentModel c, {bool isReply = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: EdgeInsets.only(bottom: 10, left: isReply ? 44 : 0),
        decoration: BoxDecoration(
          color: c.isPinned ? const Color(0xFFFFFDE7) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: c.isPinned ? Border.all(color: Colors.amber.shade300, width: 1.5) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (c.isPinned)
              Padding(padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.push_pin, size: 13, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('Pinned', style: TextStyle(fontFamily: 'Outfit',
                      fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                ])),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 16, backgroundColor: _brandColor.withValues(alpha: 0.2),
                  backgroundImage: c.authorAvatarUrl != null && c.authorAvatarUrl!.isNotEmpty
                      ? NetworkImage(c.authorAvatarUrl!) : null,
                  child: c.authorAvatarUrl == null || c.authorAvatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 14, color: _brandColor) : null),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.authorName, style: const TextStyle(fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold, fontSize: 13, color: _secondary)),
                  const SizedBox(width: 6),
                  Text(_timeAgo(c.createdAt), style: TextStyle(fontFamily: 'Outfit',
                      fontSize: 11, color: Colors.grey.shade400)),
                ]),
                const SizedBox(height: 4),
                Text(c.text, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, height: 1.5)),
              ])),
              if (_isOrganizer && !c.isPinned)
                GestureDetector(
                  onTap: () => _pin(c),
                  child: const Padding(padding: EdgeInsets.all(4),
                      child: Icon(Icons.push_pin_outlined, size: 16, color: Colors.grey)),
                ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              GestureDetector(
                onTap: () => _react(c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('👍', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('${c.reactionCount}', style: const TextStyle(fontFamily: 'Outfit',
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() => _replyingTo = c);
                  _focusNode.requestFocus();
                },
                child: Text('Reply', style: TextStyle(fontFamily: 'Outfit',
                    fontSize: 12, color: _brandColor, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
        ),
      ),
      // Replies
      if (c.replies.isNotEmpty)
        ...c.replies.map((r) => _buildCommentTile(r, isReply: true)),
    ]);
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_replyingTo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _brandColor.withValues(alpha: 0.08),
            child: Row(children: [
              const Icon(Icons.reply, size: 16, color: _brandColor),
              const SizedBox(width: 6),
              Expanded(child: Text('Replying to ${_replyingTo!.authorName}',
                  style: const TextStyle(fontFamily: 'Outfit', color: _brandColor,
                      fontSize: 12, fontWeight: FontWeight.w600))),
              GestureDetector(onTap: () => setState(() => _replyingTo = null),
                  child: const Icon(Icons.close, size: 16, color: _brandColor)),
            ]),
          ),
        Padding(
          padding: EdgeInsets.only(left: 16, right: 12, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _inputCtrl, focusNode: _focusNode,
              style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
              decoration: InputDecoration(
                hintText: _replyingTo != null ? 'Write a reply…' : 'Add a comment…',
                hintStyle: TextStyle(fontFamily: 'Outfit', color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _brandColor, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              maxLines: 3, minLines: 1,
              onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(width: 42, height: 42,
                    child: CircularProgressIndicator(color: _brandColor, strokeWidth: 2))
                : Material(
                    color: _brandColor, borderRadius: BorderRadius.circular(24),
                    child: InkWell(borderRadius: BorderRadius.circular(24), onTap: _send,
                      child: const Padding(padding: EdgeInsets.all(10),
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 22))),
                  ),
          ]),
        ),
      ]),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('💬', style: TextStyle(fontSize: 64)),
    const SizedBox(height: 16),
    Text('No comments yet', style: TextStyle(fontFamily: 'Outfit',
        fontSize: 17, color: Colors.grey.shade500)),
    const SizedBox(height: 8),
    Text('Be the first to start the discussion!', style: TextStyle(fontFamily: 'Outfit',
        fontSize: 13, color: Colors.grey.shade400)),
  ]));
}
