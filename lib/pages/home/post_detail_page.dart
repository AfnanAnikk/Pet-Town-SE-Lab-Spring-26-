import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../../widgets/options_bottom_sheet.dart';

class PostDetailPage extends StatelessWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    // Generate dummy related posts for "More to explore"
    final relatedPosts = PostModel.generateDummyPosts(6, startIndex: 20);

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
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.black26,
                      size: 64,
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
                  // Like
                  const Icon(Icons.favorite_border, size: 28),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likesCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  
                  // Comment
                  const Icon(Icons.chat_bubble_outline, size: 26),
                  const SizedBox(width: 6),
                  Text(
                    '${post.commentsCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  
                  // Share
                  const Icon(Icons.ios_share, size: 26),
                  const SizedBox(width: 16),
                  
                  // Options (Three dots)
                  GestureDetector(
                    onTap: () => showOptionsBottomSheet(context, post.authorName),
                    child: const Icon(Icons.more_horiz, size: 28),
                  ),
                  
                  const Spacer(),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3293B3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // Author Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFE0E0E0),
                    child: Icon(Icons.person, color: Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    post.authorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
            const SizedBox(height: 12),
            
            // View Comments
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'View all comments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: MasonryGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: relatedPosts.length,
                itemBuilder: (context, index) {
                  return PostCard(post: relatedPosts[index]);
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
