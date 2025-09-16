import 'package:json_annotation/json_annotation.dart';

part 'analysis_result.g.dart';

@JsonSerializable()
class AnalysisResult {
  final String id;
  final String status;
  final String? plantType;
  final String? healthStatus;
  final double? confidence;
  final List<Disease>? diseases;
  final List<Recommendation>? recommendations;
  final NutrientStatus? nutrients;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final SponsorInfo? sponsorInfo;

  AnalysisResult({
    required this.id,
    required this.status,
    this.plantType,
    this.healthStatus,
    this.confidence,
    this.diseases,
    this.recommendations,
    this.nutrients,
    this.imageUrl,
    this.createdAt,
    this.completedAt,
    this.sponsorInfo,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isFailed => status.toLowerCase() == 'failed';

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);
}

@JsonSerializable()
class Disease {
  final String name;
  final double probability;
  final String severity;
  final String description;

  Disease({
    required this.name,
    required this.probability,
    required this.severity,
    required this.description,
  });

  factory Disease.fromJson(Map<String, dynamic> json) =>
      _$DiseaseFromJson(json);

  Map<String, dynamic> toJson() => _$DiseaseToJson(this);
}

@JsonSerializable()
class Recommendation {
  final String type;
  final String priority;
  final String action;
  final String details;

  Recommendation({
    required this.type,
    required this.priority,
    required this.action,
    required this.details,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) =>
      _$RecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationToJson(this);
}

@JsonSerializable()
class NutrientStatus {
  final String nitrogen;
  final String phosphorus;
  final String potassium;

  NutrientStatus({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  factory NutrientStatus.fromJson(Map<String, dynamic> json) =>
      _$NutrientStatusFromJson(json);

  Map<String, dynamic> toJson() => _$NutrientStatusToJson(this);
}

@JsonSerializable()
class SponsorInfo {
  final String companyName;
  final String tierLevel;
  final String? logoUrl;

  SponsorInfo({
    required this.companyName,
    required this.tierLevel,
    this.logoUrl,
  });

  factory SponsorInfo.fromJson(Map<String, dynamic> json) =>
      _$SponsorInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SponsorInfoToJson(this);
}