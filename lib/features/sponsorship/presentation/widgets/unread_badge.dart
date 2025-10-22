import 'package:flutter/material.dart';

/// Badge widget that displays unread message count
/// - Shows number if count > 0
/// - Red background for unread from farmer
/// - Orange background for other unread messages
/// - Hides if count is 0 or null
class UnreadBadge extends StatelessWidget {
  final int? unreadCount;
  final bool hasUnreadFromFarmer;
  final double size;

  const UnreadBadge({
    super.key,
    required this.unreadCount,
    required this.hasUnreadFromFarmer,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    // Hide badge if no unread messages
    if (unreadCount == null || unreadCount! <= 0) {
      return const SizedBox.shrink();
    }

    // Determine background color based on sender
    final backgroundColor = hasUnreadFromFarmer ? Colors.red : Colors.orange;

    return Container(
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          unreadCount! > 99 ? '99+' : unreadCount!.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.65,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
