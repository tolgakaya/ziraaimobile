import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import '../../domain/entities/message.dart';

/// Adapter for converting between ZiraAI domain messages and flutter_chat_ui messages
class ChatMessageAdapter {
  /// Convert API Message entity to flutter_chat_ui Message
  ///
  /// [message] - Domain message from backend API
  /// [currentUserId] - Current user's ID to determine message ownership
  static chat_ui.Message toFlutterChatMessage(
    Message message,
    int currentUserId,
  ) {
    return chat_ui.TextMessage(
      id: message.idAsString,
      author: _createChatUser(message),
      text: message.text,
      createdAt: message.createdAt.millisecondsSinceEpoch,
      status: _getMessageStatus(message, currentUserId),
      metadata: {
        'messageType': message.messageType,
        'priority': message.priority,
        'category': message.category,
        'plantAnalysisId': message.plantAnalysisId,
        'senderRole': message.senderRole,
        if (message.senderCompany != null) 'senderCompany': message.senderCompany!,
      },
    );
  }

  /// Create chat user from message sender information
  static chat_ui.User _createChatUser(Message message) {
    // Build display name: prioritize company name for sponsors
    final displayName = message.isSponsorMessage && message.senderCompany != null
        ? message.senderCompany!
        : (message.senderName ?? 'Kullanıcı ${message.fromUserId}');

    return chat_ui.User(
      id: message.fromUserId.toString(),
      firstName: displayName,
      metadata: {
        'role': message.senderRole,
        if (message.senderCompany != null) 'company': message.senderCompany!,
        if (message.senderName != null) 'name': message.senderName!,
      },
    );
  }

  /// Determine message status for delivery/read receipts
  ///
  /// Only show status for current user's messages
  static chat_ui.Status? _getMessageStatus(
    Message message,
    int currentUserId,
  ) {
    // Don't show status for other users' messages
    if (message.fromUserId != currentUserId) return null;

    return message.isRead ? chat_ui.Status.seen : chat_ui.Status.delivered;
  }

  /// Convert list of domain messages to flutter_chat_ui messages
  static List<chat_ui.Message> toFlutterChatMessages(
    List<Message> messages,
    int currentUserId,
  ) {
    return messages
        .map((msg) => toFlutterChatMessage(msg, currentUserId))
        .toList();
  }
}
