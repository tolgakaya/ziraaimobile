import 'package:json_annotation/json_annotation.dart';
import '../../../plant_analysis/data/models/plant_analysis_detail_dto.dart';

part 'sponsored_analysis_detail.g.dart';

/// Sponsored Analysis Detail Response
/// Wraps complete analysis data with tier metadata
@JsonSerializable()
class SponsoredAnalysisDetailResponse {
  final SponsoredAnalysisData analysis;
  final AnalysisTierMetadata tierMetadata;

  SponsoredAnalysisDetailResponse({
    required this.analysis,
    required this.tierMetadata,
  });

  factory SponsoredAnalysisDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$SponsoredAnalysisDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredAnalysisDetailResponseToJson(this);
}

/// Analysis data with nested DTOs matching API response
@JsonSerializable()
class SponsoredAnalysisData {
  // Core fields
  final int id;
  final String? analysisId;
  final DateTime analysisDate;
  final String analysisStatus;
  final int? userId;
  final String? farmerId;
  @JsonKey(name: 'sponsor_id')
  final String? sponsorId;
  final int? sponsorUserId;
  final int? sponsorshipCodeId;

  // Nested analysis DTOs (from farmer's models)
  final PlantIdentificationDto? plantIdentification;
  final HealthAssessmentDto? healthAssessment;
  final NutrientStatusDto? nutrientStatus;
  final PestDiseaseDto? pestDisease;
  final EnvironmentalStressDto? environmentalStress;
  final SummaryDto? summary;
  final List<CrossFactorInsightDto>? crossFactorInsights;
  final RecommendationsDto? recommendations;
  final RiskAssessmentDto? riskAssessment;
  final List<ConfidenceNoteDto>? confidenceNotes;
  final ImageInfoDto? imageInfo;
  final ProcessingInfoDto? processingInfo;
  
  // Additional simple fields
  final String? cropType;
  final String? location;
  final String? farmerFriendlySummary;
  
  // Contact info (100% access)
  final String? contactPhone;
  final String? contactEmail;
  
  // Field data (100% access)
  final String? fieldId;
  final DateTime? plantingDate;
  final DateTime? expectedHarvestDate;
  final DateTime? lastFertilization;
  final DateTime? lastIrrigation;
  final List<String>? previousTreatments;
  
  // Processing metadata
  final String? urgencyLevel;
  final String? notes;
  final String? aiModel;
  final int? totalTokens;
  final double? totalCostUsd;
  final double? totalCostTry;
  final String? detailedAnalysisData;
  final TokenUsageDto? tokenUsage;
  final RequestMetadataDto? requestMetadata;
  
  // Response metadata
  final bool? success;
  final String? message;
  final bool? error;

  SponsoredAnalysisData({
    required this.id,
    this.analysisId,
    required this.analysisDate,
    required this.analysisStatus,
    this.userId,
    this.farmerId,
    this.sponsorId,
    this.sponsorUserId,
    this.sponsorshipCodeId,
    this.plantIdentification,
    this.healthAssessment,
    this.nutrientStatus,
    this.pestDisease,
    this.environmentalStress,
    this.summary,
    this.crossFactorInsights,
    this.recommendations,
    this.riskAssessment,
    this.confidenceNotes,
    this.imageInfo,
    this.processingInfo,
    this.cropType,
    this.location,
    this.farmerFriendlySummary,
    this.contactPhone,
    this.contactEmail,
    this.fieldId,
    this.plantingDate,
    this.expectedHarvestDate,
    this.lastFertilization,
    this.lastIrrigation,
    this.previousTreatments,
    this.urgencyLevel,
    this.notes,
    this.aiModel,
    this.totalTokens,
    this.totalCostUsd,
    this.totalCostTry,
    this.detailedAnalysisData,
    this.tokenUsage,
    this.requestMetadata,
    this.success,
    this.message,
    this.error,
  });

  factory SponsoredAnalysisData.fromJson(Map<String, dynamic> json) =>
      _$SponsoredAnalysisDataFromJson(json);

  Map<String, dynamic> toJson() => _$SponsoredAnalysisDataToJson(this);
  
  // Helper getters for easy access
  String? get imageUrl => imageInfo?.imageUrl;
  int? get overallHealthScore => summary?.overallHealthScore;
  String? get primaryConcern => summary?.primaryConcern;
  String? get prognosis => summary?.prognosis;
  int? get vigorScore => healthAssessment?.vigorScore;
  String? get healthSeverity => healthAssessment?.severity;
  String? get plantSpecies => plantIdentification?.species;
  String? get plantVariety => plantIdentification?.variety;
  String? get growthStage => plantIdentification?.growthStage;
  String? get primaryDeficiency => nutrientStatus?.primaryDeficiency;
}

/// Tier metadata with permissions and sponsor info
@JsonSerializable()
class AnalysisTierMetadata {
  final String tierName;
  final int accessPercentage;
  final bool canMessage;
  final bool canReply; // ✅ NEW: Sponsor can reply to farmer (conversation initiated by sponsor)
  final bool canViewLogo;
  final SponsorDisplayInfo sponsorInfo;
  final AccessibleFields accessibleFields;

  AnalysisTierMetadata({
    required this.tierName,
    required this.accessPercentage,
    required this.canMessage,
    required this.canReply,
    required this.canViewLogo,
    required this.sponsorInfo,
    required this.accessibleFields,
  });

  factory AnalysisTierMetadata.fromJson(Map<String, dynamic> json) =>
      _$AnalysisTierMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisTierMetadataToJson(this);
}

/// Sponsor display information
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

/// Permission flags for UI rendering
@JsonSerializable()
class AccessibleFields {
  // 30% Access
  final bool canViewBasicInfo;
  final bool canViewHealthScore;
  final bool canViewImages;

  // 60% Access
  final bool canViewDetailedHealth;
  final bool canViewDiseases;
  final bool canViewNutrients;
  final bool canViewRecommendations;
  final bool canViewLocation;

  // 100% Access
  final bool canViewFarmerContact;
  final bool canViewFieldData;
  final bool canViewProcessingData;

  AccessibleFields({
    required this.canViewBasicInfo,
    required this.canViewHealthScore,
    required this.canViewImages,
    required this.canViewDetailedHealth,
    required this.canViewDiseases,
    required this.canViewNutrients,
    required this.canViewRecommendations,
    required this.canViewLocation,
    required this.canViewFarmerContact,
    required this.canViewFieldData,
    required this.canViewProcessingData,
  });

  factory AccessibleFields.fromJson(Map<String, dynamic> json) =>
      _$AccessibleFieldsFromJson(json);

  Map<String, dynamic> toJson() => _$AccessibleFieldsToJson(this);
}
