import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../pages/home/post_detail_page.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isDarkened = false;
  bool _isLoved = false;
  bool _isSaved = false;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
    _checkSaveStatus();
    _checkLikeStatus();
    _fetchLiveLikesCount();
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
          _isLoved = res['data']['isLiked'] ?? false;
        });
      }
    }
  }

  Future<void> _fetchLiveLikesCount() async {
    final res = await ApiService.getPostById(int.parse(widget.post.id));
    if (res['success'] && res['data'] != null && mounted) {
      final serverCount = res['data']['likes_count'] as int?;
      if (serverCount != null) {
        setState(() {
          _likesCount = serverCount;
        });
      }
    }
  }

  Future<void> _toggleLike() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to like posts.')),
        );
      }
      return;
    }
    
    final wasLoved = _isLoved;
    setState(() {
      _isLoved = !_isLoved;
      _likesCount += _isLoved ? 1 : -1;
    });

    final res = wasLoved
        ? await ApiService.unlikePost(int.parse(widget.post.id), userId)
        : await ApiService.likePost(int.parse(widget.post.id), userId);

    if (!res['success']) {
      setState(() {
        _isLoved = wasLoved; // revert
        _likesCount += wasLoved ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like status')),
        );
      }
    } else {
      // Use server-authoritative count if returned
      final serverCount = res['data'] is Map ? res['data']['likes_count'] as int? : null;
      if (serverCount != null && mounted) {
        setState(() {
          _likesCount = serverCount;
        });
      }
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

  void _handleTap() {
    if (!_isDarkened) {
      setState(() {
        _isDarkened = true;
      });
    } else {
      _navigateToDetail();
    }
  }

  void _handleDoubleTap() {
    _navigateToDetail();
  }

  Future<void> _navigateToDetail() async {
    setState(() {
      _isDarkened = false;
    });
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: widget.post),
      ),
    );
    // Sync like/save state that may have changed inside the detail page
    if (result != null && mounted) {
      setState(() {
        _isLoved = result['isLiked'] as bool? ?? _isLoved;
        _isSaved = result['isSaved'] as bool? ?? _isSaved;
        _likesCount = result['likesCount'] as int? ?? _likesCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // The empty placeholder representing the image
            Container(
              height: widget.post.placeholderHeight,
              width: double.infinity,
              color: widget.post.placeholderColor,
              child: Center(
                child: widget.post.imagePath.startsWith('http')
                    ? Image.network(
                        widget.post.imagePath,
                        width: 256,
                        height: 256,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, color: Colors.grey),
                      )
                    : Image.asset(
                         widget.post.imagePath,
                         width: 256,
                         height: 256,
                         fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) =>
                             const Icon(Icons.image_not_supported, color: Colors.grey),
                       ),
                      ),
            ),

            // Darken Overlay & Buttons
            if (_isDarkened)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Love React Button + like count
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isLoved ? Icons.favorite : Icons.favorite_border,
                                    color: _isLoved ? Colors.red : Colors.black87.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Save Button
                          ElevatedButton(
                            onPressed: _toggleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSaved ? Colors.grey : const Color(0xFF3293B3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(60, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isSaved ? 'Saved' : 'Save',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
