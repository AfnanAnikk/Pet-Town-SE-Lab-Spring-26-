import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../../services/api_service.dart';
import '../messaging/message_list_page.dart';
import '../post/create_post_flow.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../services/call_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<PostModel> _posts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    CallService.init();
    _fetchInitialPosts();
    
    //scroll listener for endless scrolling
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMorePosts();
      }
    });
  }

  Future<void> _fetchInitialPosts() async {
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getAllPosts();
    if (result['success']) {
      final List<dynamic> data = result['data'];
      setState(() {
        _posts.clear();
        _posts.addAll(data.map((json) => PostModel.fromJson(json)).toList());
        _isLoading = false;
        _hasMore = false; // loads all posts from the db at once
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  void _loadMorePosts() {
    if (_isLoading || !_hasMore) return;
    
    // For now, getAllPosts fetches everything
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add, color: Colors.black, size: 28),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostFlow()),
            );
            if (result == true) {
              _fetchInitialPosts();
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              icon: Image.asset(
                          'assets/images/messaging.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,                       
                        ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MessageListPage()),
                );
              },
            ),
          ),
        ],
        title: const Text(
          'Pet Town',
          style: TextStyle(
            color: Color(0xFF374957),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content (Masonry Grid)
            MasonryGridView.count(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final heights = [155.0, 205.0, 175.0, 145.0, 215.0, 185.0];

                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 1 ? 30 : 0,
                  ),
                  child: SizedBox(
                    height: heights[index % heights.length],
                    child: PostCard(post: _posts[index]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
    );
  }
}