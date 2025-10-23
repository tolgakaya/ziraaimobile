import 'package:json_annotation/json_annotation.dart';

part 'analysis_list_response.g.dart';

@JsonSerializable()
class AnalysisListResponse {
  final bool success;
  final AnalysisListData? data;
  final String? message;

  AnalysisListResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory AnalysisListResponse.fromJson(Map<String, dynamic> json) =>
      _$AnalysisListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisListResponseToJson(this);
}

@JsonSerializable()
class AnalysisListData {
  final List<AnalysisSummary> analyses;
  final PaginationInfo? pagination; // Optional, backend may not send

  AnalysisListData({
    required this.analyses,
    this.pagination,
  });

  factory AnalysisListData.fromJson(Map<String, dynamic> json) =>
      _$AnalysisListDataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisListDataToJson(this);
}

@JsonSerializable()
class AnalysisSummary {
  final int id; // Backend sends int, not String

  @JsonKey(name: 'plantSpecies') // Backend field name
  final String? plantType;

  @JsonKey(name: 'primaryConcern') // Backend field name
  final String? healthStatus;

  @JsonKey(name: 'analysisDate') // Backend field name
  final DateTime date;

  final String? thumbnailUrl;

  // ==========================================
  // Messaging Fields (Flat structure - Backend v1.1)
  // ==========================================

  final int? unreadMessageCount;
  final int? totalMessageCount;
  final DateTime? lastMessageDate;
  final String? lastMessagePreview;
  final String? lastMessageSenderRole;
  final bool? hasUnreadFromSponsor; // KEY: Farmer checks if unread from SPONSOR
  final String? conversationStatus;

  AnalysisSummary({
    required this.id,
    this.plantType,
    this.healthStatus,
    required this.date,
    this.thumbnailUrl,
    this.unreadMessageCount,
    this.totalMessageCount,
    this.lastMessageDate,
    this.lastMessagePreview,
    this.lastMessageSenderRole,
    this.hasUnreadFromSponsor,
    this.conversationStatus,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) =>
      _$AnalysisSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisSummaryToJson(this);

  // ==========================================
  // Helper Getters for UI
  // ==========================================

  /// Has any messages in conversation
  bool get hasMessages => (totalMessageCount ?? 0) > 0;

  /// Has unread messages
  bool get hasUnreadMessages => (unreadMessageCount ?? 0) > 0;

  /// Is active conversation (< 7 days)
  bool get isActiveConversation => conversationStatus == 'Active';

  /// Is idle conversation (>= 7 days)
  bool get isIdleConversation => conversationStatus == 'Idle';

  /// No messages yet
  bool get hasNoMessages => conversationStatus == 'None' || conversationStatus == null;

  /// Calculate urgency score for sorting (FARMER perspective)
  int get urgencyScore {
    int score = 0;

    // 1. Okunmamış mesaj EN ÖNEMLİ
    if (hasUnreadMessages) {
      score += 1000 + ((unreadMessageCount ?? 0) * 100);
    }

    // 2. Sponsor'dan okunmamış mesaj (farmer için önemli)
    if (hasUnreadFromSponsor == true) {
      score += 500;
    }

    // 3. Aktif konuşma
    if (isActiveConversation) {
      score += 100;
    }

    return score;
  }
}

@JsonSerializable()
class PaginationInfo {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) =>
      _$PaginationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}