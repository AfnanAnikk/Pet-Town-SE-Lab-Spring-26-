import 'package:flutter/material.dart';

class PostModel {
  final String id;
  final String userId;
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
    required this.userId,
    required this.title,
    required this.authorName,
    required this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.placeholderColor,
    required this.placeholderHeight,
    required this.imagePath,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Parse color from string if available, else random
    Color color = Colors.blueGrey.shade100;
    if (json['placeholder_color'] != null && json['placeholder_color'].toString().isNotEmpty) {
      String colorStr = json['placeholder_color'].toString().replaceAll('#', '0xFF');
      if (colorStr.length == 10) {
         try { color = Color(int.parse(colorStr)); } catch (_) { /* ignore invalid color */ }
      }
    }

    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled',
      authorName: json['author_name'] ?? 'Unknown',
      tags: List<String>.from(json['tags'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      placeholderColor: color,
      placeholderHeight: (json['placeholder_height'] ?? 200).toDouble(),
      imagePath: json['image_path'] ?? 'assets/images/p1.png',
    );
  }
}