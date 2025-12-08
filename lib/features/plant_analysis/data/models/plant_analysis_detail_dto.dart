import 'package:json_annotation/json_annotation.dart';

part 'plant_analysis_detail_dto.g.dart';

@JsonSerializable()
class PlantAnalysisDetailDto {
  final int id;
  final String? analysisId;
  final DateTime analysisDate;
  final String analysisStatus;
  final int? userId;
  final String? farmerId;
  final String? sponsorId; // Optional - only if sponsor exists
  final String? location;
  final String? cropType;
  final List<String>? previousTreatments;
  final String? notes;
  final PlantIdentificationDto? plantIdentification;
  final HealthAssessmentDto? healthAssessment;
  final NutrientStatusDto? nutrientStatus;
  final PestDiseaseDto? pestDisease;
  final EnvironmentalStressDto? environmentalStress;
  final SummaryDto? summary;
  final List<CrossFactorInsightDto>? crossFactorInsights;
  final RecommendationsDto? recommendations;
  final ImageInfoDto? imageInfo;
  final ProcessingInfoDto? processingInfo;
  final RiskAssessmentDto? riskAssessment;
  final List<ConfidenceNoteDto>? confidenceNotes;
  final String? farmerFriendlySummary;
  final TokenUsageDto? tokenUsage;
  final RequestMetadataDto? requestMetadata;
  final bool success;
  final String? message;
  final bool? error;

  PlantAnalysisDetailDto({
    required this.id,
    this.analysisId,
    required this.analysisDate,
    required this.analysisStatus,
    this.userId,
    this.farmerId,
    this.sponsorId,
    this.location,
    this.cropType,
    this.previousTreatments,
    this.notes,
    this.plantIdentification,
    this.healthAssessment,
    this.nutrientStatus,
    this.pestDisease,
    this.environmentalStress,
    this.summary,
    this.crossFactorInsights,
    this.recommendations,
    this.imageInfo,
    this.processingInfo,
    this.riskAssessment,
    this.confidenceNotes,
    this.farmerFriendlySummary,
    this.tokenUsage,
    this.requestMetadata,
    required this.success,
    this.message,
    this.error,
  });

  factory PlantAnalysisDetailDto.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisDetailDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PlantAnalysisDetailDtoToJson(this);
}

@JsonSerializable()
class PlantIdentificationDto {
  final String species;
  final String? variety;
  final String growthStage;
  final double confidence;
  final List<String> identifyingFeatures;
  final List<String> visibleParts;

  PlantIdentificationDto({
    required this.species,
    this.variety,
    required this.growthStage,
    required this.confidence,
    required this.identifyingFeatures,
    required this.visibleParts,
  });

  factory PlantIdentificationDto.fromJson(Map<String, dynamic> json) =>
      _$PlantIdentificationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PlantIdentificationDtoToJson(this);
}

@JsonSerializable()
class HealthAssessmentDto {
  final int vigorScore;
  final String leafColor;
  final String leafTexture;
  final String growthPattern;
  final String structuralIntegrity;
  final String severity;
  final List<String> stressIndicators;
  final List<String> diseaseSymptoms;

  HealthAssessmentDto({
    required this.vigorScore,
    required this.leafColor,
    required this.leafTexture,
    required this.growthPattern,
    required this.structuralIntegrity,
    required this.severity,
    required this.stressIndicators,
    required this.diseaseSymptoms,
  });

  factory HealthAssessmentDto.fromJson(Map<String, dynamic> json) =>
      _$HealthAssessmentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$HealthAssessmentDtoToJson(this);
}

@JsonSerializable()
class NutrientStatusDto {
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String calcium;
  final String magnesium;
  final String sulfur;
  final String iron;
  final String zinc;
  final String manganese;
  final String boron;
  final String copper;
  final String molybdenum;
  final String chlorine;
  final String nickel;
  final String? primaryDeficiency;
  final List<String>? secondaryDeficiencies;
  final String severity;

  NutrientStatusDto({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.calcium,
    required this.magnesium,
    required this.sulfur,
    required this.iron,
    required this.zinc,
    required this.manganese,
    required this.boron,
    required this.copper,
    required this.molybdenum,
    required this.chlorine,
    required this.nickel,
    this.primaryDeficiency,
    this.secondaryDeficiencies,
    required this.severity,
  });

  factory NutrientStatusDto.fromJson(Map<String, dynamic> json) =>
      _$NutrientStatusDtoFromJson(json);
  Map<String, dynamic> toJson() => _$NutrientStatusDtoToJson(this);
}

@JsonSerializable()
class PestDiseaseDto {
  final List<PestDto> pestsDetected;
  final List<DiseaseDto> diseasesDetected;
  final String damagePattern;
  final int affectedAreaPercentage;
  final String spreadRisk;
  final String? primaryIssue;

  PestDiseaseDto({
    required this.pestsDetected,
    required this.diseasesDetected,
    required this.damagePattern,
    required this.affectedAreaPercentage,
    required this.spreadRisk,
    this.primaryIssue,
  });

  factory PestDiseaseDto.fromJson(Map<String, dynamic> json) =>
      _$PestDiseaseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PestDiseaseDtoToJson(this);
}

@JsonSerializable()
class PestDto {
  @JsonKey(name: 'name') // Backend sends "name", not "type"
  final String type;
  final String? category; // Optional - backend may not send
  final String severity;
  final List<String>? affectedParts; // Optional - backend may not send
  final double confidence;

  PestDto({
    required this.type,
    this.category,
    required this.severity,
    this.affectedParts,
    required this.confidence,
  });

  factory PestDto.fromJson(Map<String, dynamic> json) =>
      _$PestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PestDtoToJson(this);
}

@JsonSerializable()
class DiseaseDto {
  final String type;
  final String category;
  final String severity;
  final List<String> affectedParts;
  final double confidence;

  DiseaseDto({
    required this.type,
    required this.category,
    required this.severity,
    required this.affectedParts,
    required this.confidence,
  });

  factory DiseaseDto.fromJson(Map<String, dynamic> json) =>
      _$DiseaseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DiseaseDtoToJson(this);
}

@JsonSerializable()
class EnvironmentalStressDto {
  final String waterStatus;
  final String? temperatureStress;
  final String? lightStress;
  final String? physicalDamage;
  final String? chemicalDamage;
  final String primaryStressor;

  EnvironmentalStressDto({
    required this.waterStatus,
    this.temperatureStress,
    this.lightStress,
    this.physicalDamage,
    this.chemicalDamage,
    required this.primaryStressor,
  });

  factory EnvironmentalStressDto.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalStressDtoFromJson(json);
  Map<String, dynamic> toJson() => _$EnvironmentalStressDtoToJson(this);
}

@JsonSerializable()
class SummaryDto {
  final int overallHealthScore;
  final String primaryConcern;
  final List<String> secondaryConcerns;
  final int criticalIssuesCount;
  final double confidenceLevel;
  final String prognosis;
  final String estimatedYieldImpact;

  SummaryDto({
    required this.overallHealthScore,
    required this.primaryConcern,
    required this.secondaryConcerns,
    required this.criticalIssuesCount,
    required this.confidenceLevel,
    required this.prognosis,
    required this.estimatedYieldImpact,
  });

  factory SummaryDto.fromJson(Map<String, dynamic> json) =>
      _$SummaryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SummaryDtoToJson(this);
}

@JsonSerializable()
class CrossFactorInsightDto {
  final String insight;
  final double confidence;
  final List<String> affectedAspects;
  final String impactLevel;

  CrossFactorInsightDto({
    required this.insight,
    required this.confidence,
    required this.affectedAspects,
    required this.impactLevel,
  });

  factory CrossFactorInsightDto.fromJson(Map<String, dynamic> json) =>
      _$CrossFactorInsightDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CrossFactorInsightDtoToJson(this);
}

@JsonSerializable()
class RecommendationsDto {
  final List<RecommendationItemDto> immediate;
  final List<RecommendationItemDto> shortTerm;
  final List<RecommendationItemDto> preventive;
  final List<MonitoringDto> monitoring;
  final ResourceEstimationDto? resourceEstimation;
  final LocalizedRecommendationsDto? localizedRecommendations;

  RecommendationsDto({
    required this.immediate,
    required this.shortTerm,
    required this.preventive,
    required this.monitoring,
    this.resourceEstimation,
    this.localizedRecommendations,
  });

  factory RecommendationsDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendationsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationsDtoToJson(this);
}

@JsonSerializable()
class RecommendationItemDto {
  final String action;
  final String details;
  final String timeline;
  final String priority;

  RecommendationItemDto({
    required this.action,
    required this.details,
    required this.timeline,
    required this.priority,
  });

  factory RecommendationItemDto.fromJson(Map<String, dynamic> json) =>
      _$RecommendationItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationItemDtoToJson(this);

  int get priorityValue {
    const priorities = {
      'kritik': 4,
      'yüksek': 3,
      'orta': 2,
      'düşük': 1,
    };
    return priorities[priority.toLowerCase()] ?? 0;
  }
}

@JsonSerializable()
class MonitoringDto {
  final String parameter;
  final String frequency;
  final String threshold;

  MonitoringDto({
    required this.parameter,
    required this.frequency,
    required this.threshold,
  });

  factory MonitoringDto.fromJson(Map<String, dynamic> json) =>
      _$MonitoringDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MonitoringDtoToJson(this);
}

@JsonSerializable()
class ResourceEstimationDto {
  final String waterRequiredLiters;
  final String fertilizerCostEstimateUsd;
  final String laborHoursEstimate;

  ResourceEstimationDto({
    required this.waterRequiredLiters,
    required this.fertilizerCostEstimateUsd,
    required this.laborHoursEstimate,
  });

  factory ResourceEstimationDto.fromJson(Map<String, dynamic> json) =>
      _$ResourceEstimationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ResourceEstimationDtoToJson(this);
}

@JsonSerializable()
class LocalizedRecommendationsDto {
  final String region;
  final List<String> preferredPractices;
  final List<String> restrictedMethods;

  LocalizedRecommendationsDto({
    required this.region,
    required this.preferredPractices,
    required this.restrictedMethods,
  });

  factory LocalizedRecommendationsDto.fromJson(Map<String, dynamic> json) =>
      _$LocalizedRecommendationsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LocalizedRecommendationsDtoToJson(this);
}

@JsonSerializable()
class ImageInfoDto {
  final String? imageUrl;
  final String? format; // Optional - backend may not always send

  // Multi-image fields (for detailed analysis with 5 images)
  final int? totalImages;
  final List<String>? imagesProvided;
  final bool? hasLeafTop;
  final bool? hasLeafBottom;
  final bool? hasPlantOverview;
  final bool? hasRoot;
  final String? leafTopImageUrl;
  final String? leafBottomImageUrl;
  final String? plantOverviewImageUrl;
  final String? rootImageUrl;

  ImageInfoDto({
    this.imageUrl,
    this.format,
    this.totalImages,
    this.imagesProvided,
    this.hasLeafTop,
    this.hasLeafBottom,
    this.hasPlantOverview,
    this.hasRoot,
    this.leafTopImageUrl,
    this.leafBottomImageUrl,
    this.plantOverviewImageUrl,
    this.rootImageUrl,
  });

  factory ImageInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ImageInfoDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ImageInfoDtoToJson(this);
}

@JsonSerializable()
class ProcessingInfoDto {
  final DateTime processingTimestamp;
  final int processingTimeMs;
  final bool parseSuccess;
  final int retryCount;

  ProcessingInfoDto({
    required this.processingTimestamp,
    required this.processingTimeMs,
    required this.parseSuccess,
    required this.retryCount,
  });

  factory ProcessingInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ProcessingInfoDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProcessingInfoDtoToJson(this);
}

@JsonSerializable()
class RiskAssessmentDto {
  final String yieldLossProbability;
  final String timelineToWorsen;
  final String spreadPotential;

  RiskAssessmentDto({
    required this.yieldLossProbability,
    required this.timelineToWorsen,
    required this.spreadPotential,
  });

  factory RiskAssessmentDto.fromJson(Map<String, dynamic> json) =>
      _$RiskAssessmentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RiskAssessmentDtoToJson(this);
}

@JsonSerializable()
class ConfidenceNoteDto {
  final String aspect;
  final double confidence;
  final String reason;

  ConfidenceNoteDto({
    required this.aspect,
    required this.confidence,
    required this.reason,
  });

  factory ConfidenceNoteDto.fromJson(Map<String, dynamic> json) =>
      _$ConfidenceNoteDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ConfidenceNoteDtoToJson(this);
}

@JsonSerializable()
class TokenUsageDto {
  // Add fields as needed when API provides them
  TokenUsageDto();

  factory TokenUsageDto.fromJson(Map<String, dynamic> json) =>
      _$TokenUsageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TokenUsageDtoToJson(this);
}

@JsonSerializable()
class RequestMetadataDto {
  // Add fields as needed when API provides them
  RequestMetadataDto();

  factory RequestMetadataDto.fromJson(Map<String, dynamic> json) =>
      _$RequestMetadataDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RequestMetadataDtoToJson(this);
}