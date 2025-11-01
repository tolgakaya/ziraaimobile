class PlantAnalysisNotification {
  final int analysisId;
  final int userId;
  final String status;
  final DateTime completedAt;
  final String? cropType;
  final String? primaryConcern;
  final int? overallHealthScore;
  final String? imageUrl;
  final String? deepLink;
  final String? sponsorId;
  final String? message;
  final bool isRead;

  // ✅ NEW: Message notification specific fields
  final int? messageId;
  final String? fromUserName;
  final String? fromUserCompany;
  final String? senderAvatarUrl;
  final String? senderRole; // "Sponsor" or "Farmer"

  PlantAnalysisNotification({
    required this.analysisId,
    required this.userId,
    required this.status,
    required this.completedAt,
    this.cropType,
    this.primaryConcern,
    this.overallHealthScore,
    this.imageUrl,
    this.deepLink,
    this.sponsorId,
    this.message,
    this.isRead = false,
    // ✅ NEW: Message notification fields
    this.messageId,
    this.fromUserName,
    this.fromUserCompany,
    this.senderAvatarUrl,
    this.senderRole,
  });

  factory PlantAnalysisNotification.fromJson(Map<String, dynamic> json) {
    return PlantAnalysisNotification(
      analysisId: json['analysisId'] as int,
      userId: json['userId'] as int,
      status: json['status'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      cropType: json['cropType'] as String?,
      primaryConcern: json['primaryConcern'] as String?,
      overallHealthScore: json['overallHealthScore'] as int?,
      imageUrl: json['imageUrl'] as String?,
      deepLink: json['deepLink'] as String?,
      sponsorId: json['sponsorId'] as String?,
      message: json['message'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      // ✅ NEW: Parse message notification fields
      messageId: json['messageId'] as int?,
      fromUserName: json['fromUserName'] as String?,
      fromUserCompany: json['fromUserCompany'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderRole: json['senderRole'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysisId': analysisId,
      'userId': userId,
      'status': status,
      'completedAt': completedAt.toIso8601String(),
      'cropType': cropType,
      'primaryConcern': primaryConcern,
      'overallHealthScore': overallHealthScore,
      'imageUrl': imageUrl,
      'deepLink': deepLink,
      'sponsorId': sponsorId,
      'message': message,
      'isRead': isRead,
      // ✅ NEW: Include message notification fields
      'messageId': messageId,
      'fromUserName': fromUserName,
      'fromUserCompany': fromUserCompany,
      'senderAvatarUrl': senderAvatarUrl,
      'senderRole': senderRole,
    };
  }

  PlantAnalysisNotification copyWith({
    int? analysisId,
    int? userId,
    String? status,
    DateTime? completedAt,
    String? cropType,
    String? primaryConcern,
    int? overallHealthScore,
    String? imageUrl,
    String? deepLink,
    String? sponsorId,
    String? message,
    bool? isRead,
    // ✅ NEW: Message notification fields
    int? messageId,
    String? fromUserName,
    String? fromUserCompany,
    String? senderAvatarUrl,
    String? senderRole,
  }) {
    return PlantAnalysisNotification(
      analysisId: analysisId ?? this.analysisId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      cropType: cropType ?? this.cropType,
      primaryConcern: primaryConcern ?? this.primaryConcern,
      overallHealthScore: overallHealthScore ?? this.overallHealthScore,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
      sponsorId: sponsorId ?? this.sponsorId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      // ✅ NEW: Copy message notification fields
      messageId: messageId ?? this.messageId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserCompany: fromUserCompany ?? this.fromUserCompany,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      senderRole: senderRole ?? this.senderRole,
    );
  }

  // ✅ NEW: Helper methods for notification type detection
  /// Check if this is a message notification
  bool get isMessageNotification => status == 'Message';

  /// Check if this is an analysis notification (completed/failed)
  bool get isAnalysisNotification => !isMessageNotification;

  /// Get display title for notification
  String get displayTitle {
    if (isMessageNotification) {
      return 'Yeni Mesaj';
    }
    if (status == 'DealerInvitation') {
      return 'Bayilik Daveti';
    }
    return status == 'Completed' ? 'Analiz Tamamlandı' : status;
  }

  /// Get sender display name (for messages)
  String? get senderDisplayName {
    if (!isMessageNotification) return null;
    return fromUserCompany ?? fromUserName;
  }
}