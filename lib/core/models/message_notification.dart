class MessageNotification {
  final int messageId;
  final int plantAnalysisId;
  final int fromUserId;
  final String fromUserName;
  final String? fromUserCompany;
  final String senderRole; // "Sponsor" or "Farmer"
  final String message;
  final String messageType;
  final DateTime sentDate;
  final bool isApproved;
  final bool requiresApproval;

  // ✅ NEW: Avatar information from SignalR
  final String? senderAvatarUrl;
  final String? senderAvatarThumbnailUrl;

  // ✅ NEW: Attachment information from SignalR
  final bool hasAttachments;
  final int attachmentCount;
  final List<String>? attachmentUrls;
  final List<String>? attachmentThumbnails;
  final bool isVoiceMessage;
  final String? voiceMessageUrl;
  final int? voiceMessageDuration;
  final List<int>? voiceMessageWaveform;

  MessageNotification({
    required this.messageId,
    required this.plantAnalysisId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserCompany,
    required this.senderRole,
    required this.message,
    required this.messageType,
    required this.sentDate,
    required this.isApproved,
    required this.requiresApproval,
    this.senderAvatarUrl,
    this.senderAvatarThumbnailUrl,
    this.hasAttachments = false,
    this.attachmentCount = 0,
    this.attachmentUrls,
    this.attachmentThumbnails,
    this.isVoiceMessage = false,
    this.voiceMessageUrl,
    this.voiceMessageDuration,
    this.voiceMessageWaveform,
  });

  factory MessageNotification.fromJson(Map<String, dynamic> json) {
    return MessageNotification(
      messageId: json['messageId'] as int,
      plantAnalysisId: json['plantAnalysisId'] as int,
      fromUserId: json['fromUserId'] as int,
      fromUserName: json['fromUserName'] as String,
      fromUserCompany: json['fromUserCompany'] as String?,
      senderRole: json['senderRole'] as String,
      message: json['message'] as String,
      messageType: json['messageType'] as String? ?? 'Information',
      sentDate: DateTime.parse(json['sentDate'] as String),
      isApproved: json['isApproved'] as bool? ?? true,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      // ✅ NEW: Parse avatar info from SignalR
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderAvatarThumbnailUrl: json['senderAvatarThumbnailUrl'] as String?,
      // ✅ NEW: Parse attachment info from SignalR
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      attachmentCount: json['attachmentCount'] as int? ?? 0,
      attachmentUrls: (json['attachmentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      attachmentThumbnails: (json['attachmentThumbnails'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isVoiceMessage: json['isVoiceMessage'] as bool? ?? false,
      voiceMessageUrl: json['voiceMessageUrl'] as String?,
      voiceMessageDuration: json['voiceMessageDuration'] as int?,
      voiceMessageWaveform: (json['voiceMessageWaveform'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'plantAnalysisId': plantAnalysisId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserCompany': fromUserCompany,
      'senderRole': senderRole,
      'message': message,
      'messageType': messageType,
      'sentDate': sentDate.toIso8601String(),
      'isApproved': isApproved,
      'requiresApproval': requiresApproval,
      'senderAvatarUrl': senderAvatarUrl,
      'senderAvatarThumbnailUrl': senderAvatarThumbnailUrl,
      'hasAttachments': hasAttachments,
      'attachmentCount': attachmentCount,
      'attachmentUrls': attachmentUrls,
      'attachmentThumbnails': attachmentThumbnails,
      'isVoiceMessage': isVoiceMessage,
      'voiceMessageUrl': voiceMessageUrl,
      'voiceMessageDuration': voiceMessageDuration,
      'voiceMessageWaveform': voiceMessageWaveform,
    };
  }

  /// Check if this is a sponsor→farmer message (should show notification to farmer)
  bool get isSponsorMessage => senderRole == 'Sponsor';

  /// Check if this is a farmer→sponsor reply (should NOT show notification to sponsor)
  bool get isFarmerReply => senderRole == 'Farmer';
}
