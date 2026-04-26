import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../pages/home/post_detail_page.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isDarkened = false;
  bool _isLoved = false;

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

  void _navigateToDetail() {
    setState(() {
      _isDarkened = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: widget.post),
      ),
    );
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
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.black26,
                  size: 32,
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
                          // Love React Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLoved = !_isLoved;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isLoved ? Icons.favorite : Icons.favorite_border,
                                color: _isLoved ? Colors.red : Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                          
                          // Save Button
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved to your board!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3293B3),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(60, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
