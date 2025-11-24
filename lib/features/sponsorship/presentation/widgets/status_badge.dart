import 'package:flutter/material.dart';

/// Status badge widget for sponsorship inbox items
/// Shows colored badge with status text
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isUrgent;
  final int? daysUntilExpiry;

  const StatusBadge({
    super.key,
    required this.status,
    this.isUrgent = false,
    this.daysUntilExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final badgeData = _getBadgeData();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeData.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeData.icon,
            size: 14,
            color: badgeData.color,
          ),
          const SizedBox(width: 4),
          Text(
            badgeData.text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeData.color,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeData _getBadgeData() {
    // Kullanıldı (Gray)
    if (status == 'Kullanıldı') {
      return _BadgeData(
        text: 'Kullanıldı',
        color: Colors.grey,
        icon: Icons.check_circle,
      );
    }

    // Süresi Doldu (Red)
    if (status == 'Süresi Doldu') {
      return _BadgeData(
        text: 'Süresi Doldu',
        color: Colors.red,
        icon: Icons.cancel,
      );
    }

    // Urgent - ≤3 days until expiry (Orange)
    if (isUrgent && daysUntilExpiry != null) {
      return _BadgeData(
        text: '$daysUntilExpiry gün kaldı',
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
    }

    // Aktif (Green)
    return _BadgeData(
      text: 'Aktif',
      color: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }
}

class _BadgeData {
  final String text;
  final Color color;
  final IconData icon;

  _BadgeData({
    required this.text,
    required this.color,
    required this.icon,
  });
}
