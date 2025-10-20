import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';

class Message extends Equatable {
  // Core message fields
  final int id;
  final int plantAnalysisId;
  final int fromUserId;
  final int toUserId;
  final String message;
  final String senderRole;
  final String? messageType;
  final String? subject;
  final String? senderName;
  final String? senderCompany;
  final String? priority;
  final String? category;

  // Message status (existing)
  final bool isRead;
  final bool? isApproved;
  final DateTime sentDate;
  final DateTime? readDate;
  final DateTime? approvedDate;

  // ✅ NEW: Enhanced message status tracking
  final MessageStatus status;  // Sent/Delivered/Read
  final DateTime? deliveredDate;

  // ✅ NEW: Avatar support
  final String? senderAvatarUrl;
  final String? senderAvatarThumbnailUrl;

  // ✅ NEW: Attachment support
  final bool hasAttachments;
  final int attachmentCount;
  final List<String>? attachmentUrls;
  final List<String>? attachmentTypes;
  final List<int>? attachmentSizes;
  final List<String>? attachmentNames;

  // ✅ NEW: Voice message support
  final bool isVoiceMessage;
  final String? voiceMessageUrl;
  final int? voiceMessageDuration;
  final List<double>? voiceMessageWaveform;

  // ✅ NEW: Edit/Delete/Forward support
  final bool isEdited;
  final DateTime? editedDate;
  final bool isForwarded;
  final int? forwardedFromMessageId;
  final bool isActive;  // false if deleted

  const Message({
    required this.id,
    required this.plantAnalysisId,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.senderRole,
    this.messageType,
    this.subject,
    this.senderName,
    this.senderCompany,
    this.priority,
    this.category,
    required this.isRead,
    this.isApproved,
    required this.sentDate,
    this.readDate,
    this.approvedDate,
    // ✅ NEW: Enhanced status
    this.status = MessageStatus.sent,
    this.deliveredDate,
    // ✅ NEW: Avatar
    this.senderAvatarUrl,
    this.senderAvatarThumbnailUrl,
    // ✅ NEW: Attachments
    this.hasAttachments = false,
    this.attachmentCount = 0,
    this.attachmentUrls,
    this.attachmentTypes,
    this.attachmentSizes,
    this.attachmentNames,
    // ✅ NEW: Voice
    this.isVoiceMessage = false,
    this.voiceMessageUrl,
    this.voiceMessageDuration,
    this.voiceMessageWaveform,
    // ✅ NEW: Edit/Delete/Forward
    this.isEdited = false,
    this.editedDate,
    this.isForwarded = false,
    this.forwardedFromMessageId,
    this.isActive = true,
  });

  // Helper methods for business logic
  bool get isSponsorMessage => senderRole == 'Sponsor';
  bool get isFarmerMessage => senderRole == 'Farmer';
  bool get isDeleted => !isActive;
  bool get canEdit => isActive && !isVoiceMessage && !hasAttachments;
  bool get hasMedia => hasAttachments || isVoiceMessage;

  // For flutter_chat_ui compatibility
  String get idAsString => id.toString();
  String get text => message;
  DateTime get createdAt => sentDate;

  factory Message.fromModel(MessageModel model) {
    return Message(
      id: model.id,
      plantAnalysisId: model.plantAnalysisId,
      fromUserId: model.fromUserId,
      toUserId: model.toUserId,
      message: model.message,
      senderRole: model.senderRole,
      messageType: model.messageType,
      subject: model.subject,
      senderName: model.senderName,
      senderCompany: model.senderCompany,
      priority: model.priority,
      category: model.category,
      isRead: model.isRead,
      isApproved: model.isApproved,
      sentDate: model.sentDate,
      readDate: model.readDate,
      approvedDate: model.approvedDate,
      // ✅ NEW: Enhanced fields
      status: model.status,
      deliveredDate: model.deliveredDate,
      senderAvatarUrl: model.senderAvatarUrl,
      senderAvatarThumbnailUrl: model.senderAvatarThumbnailUrl,
      hasAttachments: model.hasAttachments,
      attachmentCount: model.attachmentCount,
      attachmentUrls: model.attachmentUrls,
      attachmentTypes: model.attachmentTypes,
      attachmentSizes: model.attachmentSizes,
      attachmentNames: model.attachmentNames,
      isVoiceMessage: model.isVoiceMessage,
      voiceMessageUrl: model.voiceMessageUrl,
      voiceMessageDuration: model.voiceMessageDuration,
      voiceMessageWaveform: model.voiceMessageWaveform,
      isEdited: model.isEdited,
      editedDate: model.editedDate,
      isForwarded: model.isForwarded,
      forwardedFromMessageId: model.forwardedFromMessageId,
      isActive: model.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        plantAnalysisId,
        fromUserId,
        toUserId,
        message,
        senderRole,
        messageType,
        subject,
        senderName,
        senderCompany,
        priority,
        category,
        isRead,
        isApproved,
        sentDate,
        readDate,
        approvedDate,
        status,
        deliveredDate,
        senderAvatarUrl,
        senderAvatarThumbnailUrl,
        hasAttachments,
        attachmentCount,
        attachmentUrls,
        attachmentTypes,
        attachmentSizes,
        attachmentNames,
        isVoiceMessage,
        voiceMessageUrl,
        voiceMessageDuration,
        voiceMessageWaveform,
        isEdited,
        editedDate,
        isForwarded,
        forwardedFromMessageId,
        isActive,
      ];
}

// ✅ NEW: Message status enum
enum MessageStatus {
  sent,
  delivered,
  read;

  static MessageStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }
}

// ✅ NEW: Message type enum
enum MessageType {
  text,
  information,
  warning,
  voiceMessage;

  static MessageType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'information':
        return MessageType.information;
      case 'warning':
        return MessageType.warning;
      case 'voicemessage':
        return MessageType.voiceMessage;
      default:
        return MessageType.text;
    }
  }
}
