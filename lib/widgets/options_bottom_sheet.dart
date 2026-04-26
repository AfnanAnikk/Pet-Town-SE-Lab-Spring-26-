import 'package:flutter/material.dart';

class OptionsBottomSheet extends StatelessWidget {
  final String authorName;

  const OptionsBottomSheet({super.key, required this.authorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Options
              _buildOption('Follow $authorName'),
              _buildOption('Copy link'),
              _buildOption('Download image'),
              _buildOption('See more like this'),
              _buildOption('See less like this'),
              _buildOption('Report this pin'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}

void showOptionsBottomSheet(BuildContext context, String authorName) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => OptionsBottomSheet(authorName: authorName),
  );
}
