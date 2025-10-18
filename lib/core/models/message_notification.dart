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
    };
  }

  /// Check if this is a sponsor→farmer message (should show notification to farmer)
  bool get isSponsorMessage => senderRole == 'Sponsor';

  /// Check if this is a farmer→sponsor reply (should NOT show notification to sponsor)
  bool get isFarmerReply => senderRole == 'Farmer';
}
