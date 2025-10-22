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

  // ✅ NEW: Attachment information from SignalR
  final bool hasAttachments;
  final int attachmentCount;
  final bool isVoiceMessage;
  final int? voiceMessageDuration;

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
    this.hasAttachments = false,
    this.attachmentCount = 0,
    this.isVoiceMessage = false,
    this.voiceMessageDuration,
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
      // ✅ NEW: Parse attachment info from SignalR
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      attachmentCount: json['attachmentCount'] as int? ?? 0,
      isVoiceMessage: json['isVoiceMessage'] as bool? ?? false,
      voiceMessageDuration: json['voiceMessageDuration'] as int?,
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
      'hasAttachments': hasAttachments,
      'attachmentCount': attachmentCount,
      'isVoiceMessage': isVoiceMessage,
      'voiceMessageDuration': voiceMessageDuration,
    };
  }

  /// Check if this is a sponsor→farmer message (should show notification to farmer)
  bool get isSponsorMessage => senderRole == 'Sponsor';

  /// Check if this is a farmer→sponsor reply (should NOT show notification to sponsor)
  bool get isFarmerReply => senderRole == 'Farmer';
}
