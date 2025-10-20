import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/message.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
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
  final MessageStatus status;
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
  final bool isActive;

  MessageModel({
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

  // ✅ Custom fromJson to handle backend response properly
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      plantAnalysisId: json['plantAnalysisId'] as int,
      fromUserId: json['fromUserId'] as int,
      toUserId: json['toUserId'] as int,
      message: json['message'] as String? ?? '',
      senderRole: json['senderRole'] as String? ?? '',
      messageType: json['messageType'] as String?,
      subject: json['subject'] as String?,
      senderName: json['senderName'] as String?,
      senderCompany: json['senderCompany'] as String?,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      isApproved: json['isApproved'] as bool?,
      sentDate: DateTime.parse(json['sentDate'] as String),
      readDate: json['readDate'] != null ? DateTime.parse(json['readDate'] as String) : null,
      approvedDate: json['approvedDate'] != null ? DateTime.parse(json['approvedDate'] as String) : null,
      // ✅ NEW: Enhanced status
      status: MessageStatus.fromString(json['messageStatus'] as String?),
      deliveredDate: json['deliveredDate'] != null ? DateTime.parse(json['deliveredDate'] as String) : null,
      // ✅ NEW: Avatar
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderAvatarThumbnailUrl: json['senderAvatarThumbnailUrl'] as String?,
      // ✅ NEW: Attachments
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      attachmentCount: json['attachmentCount'] as int? ?? 0,
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      attachmentTypes: (json['attachmentTypes'] as List<dynamic>?)?.map((e) => e as String).toList(),
      attachmentSizes: (json['attachmentSizes'] as List<dynamic>?)?.map((e) => e as int).toList(),
      attachmentNames: (json['attachmentNames'] as List<dynamic>?)?.map((e) => e as String).toList(),
      // ✅ NEW: Voice
      isVoiceMessage: json['voiceMessageUrl'] != null,
      voiceMessageUrl: json['voiceMessageUrl'] as String?,
      voiceMessageDuration: json['voiceMessageDuration'] as int?,
      voiceMessageWaveform: json['voiceMessageWaveform'] != null
          ? (jsonDecode(json['voiceMessageWaveform'] as String) as List<dynamic>).map((e) => (e as num).toDouble()).toList()
          : null,
      // ✅ NEW: Edit/Delete/Forward
      isEdited: json['isEdited'] as bool? ?? false,
      editedDate: json['editedDate'] != null ? DateTime.parse(json['editedDate'] as String) : null,
      isForwarded: json['isForwarded'] as bool? ?? false,
      forwardedFromMessageId: json['forwardedFromMessageId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}
