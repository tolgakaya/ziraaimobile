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
