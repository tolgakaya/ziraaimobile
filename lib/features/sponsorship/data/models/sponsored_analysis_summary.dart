import 'package:json_annotation/json_annotation.dart';

part 'sponsored_analysis_summary.g.dart';

/// Main analysis item DTO with tier-based field visibility
/// Follows ZiraAI backend response structure from /api/v1/sponsorship/analyses
@JsonSerializable()
class SponsoredAnalysisSummary {
  // ==========================================
  // Core Fields (Always Available - All Tiers)
  // ==========================================
  
  final int analysisId;
  final DateTime analysisDate;
  final String analysisStatus;
  final String? cropType;

  // ==========================================
  // 30% Access Fields (S & M Tiers)
  // ==========================================
  
  final double? overallHealthScore;
  final String? plantSpecies;
  final String? plantVariety;
  final String? growthStage;
  final String? imageUrl;

  // ==========================================
  // 60% Access Fields (L Tier)
  // ==========================================
  
  final double? vigorScore;
  final String? healthSeverity;
  final String? primaryConcern;

  // ==========================================
  // Tier & Permission Info (May be null if not provided by backend)
  // ==========================================
  
  final String? tierName;
  final int? accessPercentage;
  final bool? canMessage;
  final bool? canViewLogo;

  // ==========================================
  // Sponsor Display Info (May be null if not provided by backend)
  // ==========================================

  final SponsorDisplayInfo? sponsorInfo;

  // ==========================================
  // Messaging Fields (Flat structure - Backend v1.1)
  // ==========================================

  final int? unreadMessageCount;
  final int? totalMessageCount;
  final DateTime? lastMessageDate;
  final String? lastMessagePreview;
  final String? lastMessageSenderRole;
  final bool? hasUnreadFromFarmer;
  final String? conversationStatus;

  SponsoredAnalysisSummary({
    required this.analysisId,
    required this.analysisDate,
    required this.analysisStatus,
    this.cropType,
    this.overallHealthScore,
    this.plantSpecies,
    this.plantVariety,
    this.growthStage,
    this.imageUrl,
    this.vigorScore,
    this.healthSeverity,
    this.primaryConcern,
    this.tierName,
    this.accessPercentage,
    this.canMessage,
    this.canViewLogo,
    this.sponsorInfo,
    this.unreadMessageCount,
    this.totalMessageCount,
    this.lastMessageDate,
    this.lastMessagePreview,
    this.lastMessageSenderRole,
    this.hasUnreadFromFarmer,
    this.conversationStatus,
  });

  factory SponsoredAnalysisSummary.fromJson(Map<String, dynamic> json) =>
      _$SponsoredAnalysisSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredAnalysisSummaryToJson(this);

  // ==========================================
  // Helper Getters for UI
  // ==========================================

  /// Has basic access (30%) - S & M tiers
  bool get hasBasicAccess => (accessPercentage ?? 0) >= 30;

  /// Has detailed access (60%) - L tier
  bool get hasDetailedAccess => (accessPercentage ?? 0) >= 60;

  /// Has full access (100%) - XL tier
  bool get hasFullAccess => (accessPercentage ?? 0) >= 100;

  /// Formatted health score text
  String get healthScoreText {
    if (overallHealthScore == null) return 'N/A';
    return '${overallHealthScore!.toStringAsFixed(1)}%';
  }

  /// User-friendly date formatting (Turkish)
  String get analysisDateFormatted {
    final now = DateTime.now();
    final difference = now.difference(analysisDate);

    if (difference.inDays == 0) {
      return 'Bugün ${analysisDate.hour}:${analysisDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} hafta önce';
    } else {
      return '${analysisDate.day}/${analysisDate.month}/${analysisDate.year}';
    }
  }

  // ==========================================
  // Messaging Helper Getters
  // ==========================================

  /// Has any messages in conversation
  bool get hasMessages => (totalMessageCount ?? 0) > 0;

  /// Has unread messages from farmer
  bool get hasUnreadMessages => (unreadMessageCount ?? 0) > 0;

  /// Is active conversation (< 7 days)
  bool get isActiveConversation => conversationStatus == 'Active';

  /// Is idle conversation (>= 7 days)
  bool get isIdleConversation => conversationStatus == 'Idle';

  /// No messages yet
  bool get hasNoMessages => conversationStatus == 'None' || conversationStatus == null;

  /// Calculate urgency score for sorting
  int get urgencyScore {
    int score = 0;

    // 1. Okunmamış mesaj EN ÖNEMLİ
    if (hasUnreadMessages) {
      score += 1000 + ((unreadMessageCount ?? 0) * 100);
    }

    // 2. Çiftçiden okunmamış mesaj
    if (hasUnreadFromFarmer == true) {
      score += 500;
    }

    // 3. Düşük sağlık skoru
    if (overallHealthScore != null && overallHealthScore! < 50) {
      score += 200;
    }

    // 4. Aktif konuşma
    if (isActiveConversation) {
      score += 100;
    }

    return score;
  }
}

/// Sponsor branding and company information
@JsonSerializable()
class SponsorDisplayInfo {
  final int sponsorId;
  final String companyName;
  final String? logoUrl;
  final String? websiteUrl;

  SponsorDisplayInfo({
    required this.sponsorId,
    required this.companyName,
    this.logoUrl,
    this.websiteUrl,
  });

  factory SponsorDisplayInfo.fromJson(Map<String, dynamic> json) =>
      _$SponsorDisplayInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorDisplayInfoToJson(this);
}
