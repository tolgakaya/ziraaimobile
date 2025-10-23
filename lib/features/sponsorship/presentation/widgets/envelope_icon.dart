import 'package:flutter/material.dart';

/// Envelope icon widget that shows message status visually
/// - Closed envelope (filled): Has unread messages from farmer
/// - Closed envelope (outlined): Has messages but all read
/// - Open envelope: Active conversation (messages exchanged)
/// - No envelope: No messages yet
class EnvelopeIcon extends StatelessWidget {
  final bool hasMessages;
  final bool hasUnreadMessages;
  final bool hasUnreadFromFarmer;
  final bool isActiveConversation;
  final double size;

  const EnvelopeIcon({
    super.key,
    required this.hasMessages,
    required this.hasUnreadMessages,
    required this.hasUnreadFromFarmer,
    required this.isActiveConversation,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    // No envelope if no messages
    if (!hasMessages) {
      return const SizedBox.shrink();
    }

    // Determine icon and color based on status
    IconData iconData;
    Color iconColor;

    if (hasUnreadFromFarmer) {
      // Closed envelope (filled) with red color - highest priority
      iconData = Icons.mail;
      iconColor = Colors.red;
    } else if (hasUnreadMessages) {
      // Closed envelope (filled) with orange color
      iconData = Icons.mail;
      iconColor = Colors.orange;
    } else if (isActiveConversation) {
      // Open envelope (outlined) with blue color - active conversation
      iconData = Icons.mail_outline;
      iconColor = Colors.blue;
    } else {
      // Open envelope (outlined) with grey color - idle conversation
      iconData = Icons.mail_outline;
      iconColor = Colors.grey;
    }

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}
