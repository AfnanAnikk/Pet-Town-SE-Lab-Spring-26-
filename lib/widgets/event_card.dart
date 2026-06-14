// lib/widgets/event_card.dart
// Pet Town – Premium Event Card Widget

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import 'event_status_badge.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  static const _brandColor = Color(0xFF3293B3);
  static const _accentColor = Color(0xFF2596BE);

  static const _shadow = BoxShadow(
    color: Color(0x14000000), // black ~8% alpha
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'competition':
        return Icons.emoji_events_rounded;
      case 'adoption':
        return Icons.favorite_rounded;
      case 'training':
        return Icons.school_rounded;
      case 'meetup':
        return Icons.people_rounded;
      case 'health':
      case 'vet':
        return Icons.local_hospital_rounded;
      case 'grooming':
        return Icons.content_cut_rounded;
      case 'show':
        return Icons.star_rounded;
      case 'charity':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _petTypeEmoji(String petType) {
    switch (petType.toLowerCase()) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐈';
      case 'bird':
        return '🦜';
      case 'rabbit':
        return '🐇';
      case 'fish':
        return '🐟';
      case 'reptile':
        return '🦎';
      case 'hamster':
        return '🐹';
      case 'all':
        return '🐾';
      default:
        return '🐾';
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('EEE, MMM d • h:mm a').format(dt);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [_shadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCoverImage(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cover image with overlays ─────────────────────────────────────────────

  Widget _buildCoverImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image or gradient placeholder
          _buildImageOrPlaceholder(),

          // Bottom gradient for text legibility
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000)],
                stops: [0.4, 1.0],
              ),
            ),
          ),

          // Top row: category icon (left) + status badge (right)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryIconBubble(),
                const Spacer(),
                EventStatusBadge(status: event.status),
              ],
            ),
          ),

          // Bottom text overlay: title + date + location
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildTextOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    if (event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty) {
      return Image.network(
        event.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientPlaceholder(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _gradientPlaceholder();
        },
      );
    }
    return _gradientPlaceholder();
  }

  Widget _gradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brandColor, _accentColor],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.event_rounded,
          color: Colors.white38,
          size: 56,
        ),
      ),
    );
  }

  Widget _buildCategoryIconBubble() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Icon(
        _categoryIcon(event.category),
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildTextOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          event.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.2,
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 6),

        // Date row
        Row(
          children: [
            const Icon(Icons.schedule_rounded,
                color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _formatDate(event.startDatetime),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),

        // Location row
        Row(
          children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.white70, size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                event.location,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Footer row ────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          // ── Left: chip (Expanded so it fills remaining space and ellipses)
          Expanded(
            child: _PetTypeChip(
              emoji: _petTypeEmoji(event.petType),
              label: event.petType,
            ),
          ),

          // Organizer avatar (optional)
          if (event.organizerAvatarUrl != null || event.organizerName != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _buildOrganizerAvatar(),
            ),

          const SizedBox(width: 8),

          // ── Right: fixed-size badges + bookmark (mainAxisSize:min = rigid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountBadge(
                icon: Icons.check_circle_outline_rounded,
                count: event.goingCount,
                color: const Color(0xFF2ECC71),
                tooltip: 'Going',
              ),
              const SizedBox(width: 6),
              _CountBadge(
                icon: Icons.star_outline_rounded,
                count: event.interestedCount,
                color: const Color(0xFFF39C12),
                tooltip: 'Interested',
              ),
              const SizedBox(width: 4),
              _BookmarkButton(isSaved: isSaved, onTap: onSave),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerAvatar() {
    return Tooltip(
      message: event.organizerName ?? 'Organizer',
      child: CircleAvatar(
        radius: 14,
        backgroundColor: _brandColor.withValues(alpha: 0.15),
        backgroundImage: event.organizerAvatarUrl != null
            ? NetworkImage(event.organizerAvatarUrl!)
            : null,
        child: event.organizerAvatarUrl == null
            ? Text(
                (event.organizerName?.isNotEmpty == true)
                    ? event.organizerName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _brandColor,
                ),
              )
            : null,
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PetTypeChip extends StatelessWidget {
  final String emoji;
  final String label;

  const _PetTypeChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCE8F2), width: 1),
      ),
      // No mainAxisSize:min – the Row fills the width that Flexible allocates,
      // which prevents overflow when the chip is squeezed in a tight layout.
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3293B3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String tooltip;

  const _CountBadge({
    required this.icon,
    required this.count,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 2),
          Text(
            _formatCount(count),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _BookmarkButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback? onTap;

  const _BookmarkButton({required this.isSaved, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            key: ValueKey(isSaved),
            color: isSaved ? const Color(0xFF3293B3) : const Color(0xFFAABBCA),
            size: 22,
          ),
        ),
      ),
    );
  }
}
