import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import '../../domain/entities/message.dart' as domain;

/// Adapter for converting between ZiraAI domain messages and flutter_chat_ui messages
class ChatMessageAdapter {
  /// Convert API Message entity to flutter_chat_ui Message
  ///
  /// [message] - Domain message from backend API
  /// [currentUserId] - Current user's ID to determine message ownership
  static chat_core.Message toFlutterChatMessage(
    domain.Message message,
    int currentUserId,
  ) {
    // ✅ Handle different message types
    if (message.isVoiceMessage && message.voiceMessageUrl != null) {
      // Voice message
      return chat_core.Message.custom(
        id: message.idAsString,
        authorId: message.fromUserId.toString(),
        createdAt: message.createdAt,
        status: _getMessageStatus(message, currentUserId),
        metadata: _buildMetadata(message),
      );
    } else if (message.hasAttachments && message.attachmentUrls != null) {
      // Message with attachments (images/files)
      return chat_core.Message.custom(
        id: message.idAsString,
        authorId: message.fromUserId.toString(),
        createdAt: message.createdAt,
        status: _getMessageStatus(message, currentUserId),
        metadata: _buildMetadata(message),
      );
    } else {
      // Regular text message
      return chat_core.Message.text(
        id: message.idAsString,
        authorId: message.fromUserId.toString(),
        text: message.text,
        createdAt: message.createdAt,
        status: _getMessageStatus(message, currentUserId),
        metadata: _buildMetadata(message),
      );
    }
  }

  /// Build comprehensive metadata for message
  static Map<String, dynamic> _buildMetadata(domain.Message message) {
    return {
      // Basic message info
      'messageType': message.messageType,
      'priority': message.priority,
      'category': message.category,
      'plantAnalysisId': message.plantAnalysisId,
      'senderRole': message.senderRole,
      if (message.senderCompany != null) 'senderCompany': message.senderCompany!,
      if (message.senderName != null) 'senderName': message.senderName!,

      // ✅ NEW: Avatar URLs
      if (message.senderAvatarUrl != null) 'senderAvatarUrl': message.senderAvatarUrl!,
      if (message.senderAvatarThumbnailUrl != null) 'senderAvatarThumbnailUrl': message.senderAvatarThumbnailUrl!,

      // ✅ NEW: Message status
      'messageStatus': message.status.name,
      if (message.deliveredDate != null) 'deliveredDate': message.deliveredDate!.toIso8601String(),
      if (message.readDate != null) 'readDate': message.readDate!.toIso8601String(),

      // ✅ NEW: Attachments
      'hasAttachments': message.hasAttachments,
      'attachmentCount': message.attachmentCount,
      if (message.attachmentUrls != null) 'attachmentUrls': message.attachmentUrls!,
      if (message.attachmentTypes != null) 'attachmentTypes': message.attachmentTypes!,
      if (message.attachmentSizes != null) 'attachmentSizes': message.attachmentSizes!,
      if (message.attachmentNames != null) 'attachmentNames': message.attachmentNames!,

      // ✅ NEW: Voice message
      'isVoiceMessage': message.isVoiceMessage,
      if (message.voiceMessageUrl != null) 'voiceMessageUrl': message.voiceMessageUrl!,
      if (message.voiceMessageDuration != null) 'voiceMessageDuration': message.voiceMessageDuration!,
      if (message.voiceMessageWaveform != null) 'voiceMessageWaveform': message.voiceMessageWaveform!,

      // ✅ NEW: Edit/Delete/Forward
      'isEdited': message.isEdited,
      if (message.editedDate != null) 'editedDate': message.editedDate!.toIso8601String(),
      'isForwarded': message.isForwarded,
      if (message.forwardedFromMessageId != null) 'forwardedFromMessageId': message.forwardedFromMessageId!,
      'isActive': message.isActive,
      'isDeleted': message.isDeleted,
    };
  }

  /// Determine message status for delivery/read receipts
  ///
  /// Only show status for current user's messages
  static chat_core.MessageStatus? _getMessageStatus(
    domain.Message message,
    int currentUserId,
  ) {
    // Don't show status for other users' messages
    if (message.fromUserId != currentUserId) return null;

    // ✅ Use enhanced message status
    switch (message.status) {
      case domain.MessageStatus.read:
        return chat_core.MessageStatus.seen;
      case domain.MessageStatus.delivered:
        return chat_core.MessageStatus.delivered;
      case domain.MessageStatus.sent:
        return chat_core.MessageStatus.sent;
    }
  }

  /// Convert list of domain messages to flutter_chat_ui messages
  static List<chat_core.Message> toFlutterChatMessages(
    List<domain.Message> messages,
    int currentUserId,
  ) {
    return messages
        .map((msg) => toFlutterChatMessage(msg, currentUserId))
        .toList();
  }
}
