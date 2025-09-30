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
    );
  }
}