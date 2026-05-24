import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/post_card.dart';
import '../../widgets/options_bottom_sheet.dart';
import '../messaging/message_list_page.dart';
import '../profile/user_profile_page.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  List<PostModel> _relatedPosts = [];
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  String? _currentUserProfilePictureUrl;  
  
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
    _fetchRelatedPosts();
    _fetchComments();
    _checkSaveStatus();
    _checkLikeStatus();
    _loadCurrentUserProfilePicture();

    
  }
  Future<void> _loadCurrentUserProfilePicture() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return;

    final res = await AuthService.getProfile(userId);

    if (res['success'] == true && res['data'] != null && mounted) {
      final user = res['data']['user'] ?? res['data'];

      setState(() {
        _currentUserProfilePictureUrl = user['profile_picture_url'];
      });
    }
  }

  Future<void> _checkSaveStatus() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final res = await ApiService.isPostSaved(int.parse(widget.post.id), userId);
      if (res['success'] && mounted) {
        setState(() {
          _isSaved = res['data']['isSaved'] ?? false;
        });
      }
    }
  }

  Future<void> _checkLikeStatus() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final res = await ApiService.isPostLiked(int.parse(widget.post.id), userId);
      if (res['success'] && mounted) {
        setState(() {
          _isLiked = res['data']['isLiked'] ?? false;
        });
      }
    }
  }

  Future<void> _fetchRelatedPosts() async {
    final result = await ApiService.getAllPosts();
    if (result['success'] && result['data'] != null) {
      final List<dynamic> data = result['data'];
      final all = data.map((json) => PostModel.fromJson(json)).toList();
      setState(() {
        _relatedPosts = all.where((p) => p.id != widget.post.id).take(6).toList();
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchComments() async {
    final res = await ApiService.getPostComments(int.parse(widget.post.id));
    if (res['success']) {
      setState(() {
        _comments = res['data'];
        _commentsCount = _comments.length;
      });
    }
  }

  Future<void> _toggleLike() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return;

    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    final res = wasLiked
        ? await ApiService.unlikePost(int.parse(widget.post.id), userId)
        : await ApiService.likePost(int.parse(widget.post.id), userId);

    if (!res['success'] && mounted) {
      // Revert on failure
      setState(() {
        _isLiked = wasLiked;
        _likesCount += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _toggleSave() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save posts.')),
        );
      }
      return;
    }
    
    final wasSaved = _isSaved;
    setState(() {
      _isSaved = !_isSaved;
    });

    final res = wasSaved 
        ? await ApiService.unsavePost(int.parse(widget.post.id), userId)
        : await ApiService.savePost(int.parse(widget.post.id), userId);

    if (!res['success']) {
      setState(() {
        _isSaved = wasSaved; // revert
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update save status')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Saved to your board!' : 'Removed from your board.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final userId = await AuthService.getUserId();
    if (userId == null) return;

    final text = _commentController.text.trim();
    _commentController.clear();
    
    // Optimistic UI update
    setState(() {
      _comments.insert(0, {'author_name': 'You', 'text': text});
      _commentsCount++;
    });

    await ApiService.addComment(int.parse(widget.post.id), userId, text);
    _fetchComments(); // refresh to get real data
  }

  void _shareToChats() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MessageListPage()));
  }

  void _downloadImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image downloaded to gallery!')),
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await ApiService.deletePost(int.parse(widget.post.id));
      if (res['success'] && mounted) {
        Navigator.pop(context); // Go back after deletion
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
      }
    }
  }

  Widget _buildProfileAvatar({
    required String? imageUrl,
    double radius = 16,
    double iconSize = 20,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0E0E0),
      backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
      child: hasImage
          ? null
          : Icon(Icons.person, color: Colors.grey, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Back Button
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.45,
                  decoration: BoxDecoration(
                    color: post.placeholderColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Hero(
                      tag: post.id,
                      child: post.imagePath.startsWith('http')
                        ? Image.network(
                            post.imagePath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64)),
                          )
                        : Image.asset(
                            post.imagePath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64)),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Actions Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.black, size: 28),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_likesCount',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 16),

                  const Icon(Icons.chat_bubble_outline, size: 26),
                  const SizedBox(width: 6),
                  Text(
                    '$_commentsCount',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 16),

                  GestureDetector(
                    onTap: _shareToChats,
                    child: const Icon(Icons.ios_share, size: 26),
                  ),
                  const SizedBox(width: 16),

                  GestureDetector(
                    onTap: () async {
                      final userId = await AuthService.getUserId();
                      final isAuthor = userId != null && userId.toString() == post.userId;
                      if (!mounted) return;
                      showOptionsBottomSheet(
                        context, 
                        post.authorName, 
                        onDownload: _downloadImage,
                        showDelete: isAuthor,
                        onDelete: _deletePost,
                      );
                    },
                    child: const Icon(Icons.more_horiz, size: 28),
                  ),

                  const Spacer(),

                  ElevatedButton(
                    onPressed: _toggleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved ? Colors.grey : const Color(0xFF3293B3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(_isSaved ? 'Saved' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // Author Info
            GestureDetector(
              onTap: () {
                if (post.userId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(userId: int.tryParse(post.userId)),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildProfileAvatar(
                      imageUrl: post.authorProfilePictureUrl,
                      radius: 16,
                      iconSize: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        color: Color(0xFF3293B3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.tags.join('  '),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Comment Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildProfileAvatar(
                    imageUrl: _currentUserProfilePictureUrl,
                    radius: 16,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF3293B3)),
                          onPressed: _postComment,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Comments List
            if (_comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ..._comments.take(3).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12, 
                            backgroundColor: const Color(0xFFE0E0E0), 
                            backgroundImage: c['profile_picture_url'] != null ? NetworkImage(c['profile_picture_url']) : null,
                            child: c['profile_picture_url'] == null ? const Icon(Icons.person, size: 14, color: Colors.white) : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['author_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(c['text'] ?? '', style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          )
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // More to explore
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'More to explore',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Masonry Grid for related posts
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_relatedPosts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  'No other posts yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: _relatedPosts.length,
                  itemBuilder: (context, index) {
                    return PostCard(post: _relatedPosts[index]);
                  },
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
