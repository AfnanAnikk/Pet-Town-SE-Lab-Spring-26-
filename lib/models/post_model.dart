import 'package:flutter/material.dart';

class PostModel {
  final String id;
  final String title;
  final String authorName;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final Color placeholderColor;
  final double placeholderHeight;
  final String imagePath;

  PostModel({
    required this.id,
    required this.title,
    required this.authorName,
    required this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.placeholderColor,
    required this.placeholderHeight,
    required this.imagePath,
  });

  static List<PostModel> generateDummyPosts(int count, {int startIndex = 0}) {
    final colors = [
      Colors.blueGrey.shade100,
      Colors.brown.shade100,
      Colors.teal.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.red.shade100,
    ];

    final heights = [180.0, 220.0, 260.0, 300.0, 150.0];

    // random-looking order, then repeats
    final imageOrder = [3, 8, 1, 10, 5, 2, 7, 4, 9, 6];

    return List.generate(count, (index) {
      final actualIndex = startIndex + index;
      final imageNumber = imageOrder[actualIndex % imageOrder.length];

      return PostModel(
        id: 'post_$actualIndex',
        title: 'Pookie cat $actualIndex',
        authorName: 'Monica Teller',
        tags: const ['#CatLover', '#SmallCat', '#CuteCat'],
        likesCount: 138 + actualIndex * 2,
        commentsCount: 6 + actualIndex,
        placeholderColor: colors[actualIndex % colors.length],
        placeholderHeight: heights[actualIndex % heights.length],
        imagePath: 'assets/images/p$imageNumber.png',
      );
    });
  }
}