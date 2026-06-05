// lib/widgets/event_status_badge.dart
// Pet Town – Event Status Badge Widget

import 'package:flutter/material.dart';

class EventStatusBadge extends StatelessWidget {
  final String status;

  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return _StatusConfig(
          color: const Color(0xFF3293B3),
          icon: Icons.schedule_rounded,
          label: 'Upcoming',
        );
      case 'ongoing':
        return _StatusConfig(
          color: const Color(0xFF2ECC71),
          icon: Icons.radio_button_checked_rounded,
          label: 'Ongoing',
        );
      case 'completed':
        return _StatusConfig(
          color: const Color(0xFF95A5A6),
          icon: Icons.check_circle_rounded,
          label: 'Completed',
        );
      case 'cancelled':
        return _StatusConfig(
          color: const Color(0xFFE74C3C),
          icon: Icons.cancel_rounded,
          label: 'Cancelled',
        );
      case 'draft':
        return _StatusConfig(
          color: const Color(0xFFF39C12),
          icon: Icons.edit_rounded,
          label: 'Draft',
        );
      default:
        return _StatusConfig(
          color: const Color(0xFF3293B3),
          icon: Icons.event_rounded,
          label: status,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;

  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}
