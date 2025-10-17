import 'package:json_annotation/json_annotation.dart';

part 'analysis_recommendations.g.dart';

/// Analysis Recommendations Model
/// Parses the recommendations JSON string from analysis detail
@JsonSerializable()
class AnalysisRecommendations {
  final List<RecommendationAction> immediate;
  
  @JsonKey(name: 'short_term')
  final List<RecommendationAction> shortTerm;
  
  final List<RecommendationAction> preventive;
  
  final List<RecommendationAction> monitoring;
  
  @JsonKey(name: 'resource_estimation')
  final ResourceEstimation? resourceEstimation;
  
  @JsonKey(name: 'localized_recommendations')
  final LocalizedRecommendations? localizedRecommendations;

  AnalysisRecommendations({
    required this.immediate,
    required this.shortTerm,
    required this.preventive,
    required this.monitoring,
    this.resourceEstimation,
    this.localizedRecommendations,
  });

  factory AnalysisRecommendations.fromJson(Map<String, dynamic> json) =>
      _$AnalysisRecommendationsFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisRecommendationsToJson(this);
}

@JsonSerializable()
class RecommendationAction {
  final String action;
  final String? details;
  final String? priority;
  final String? timeline;

  RecommendationAction({
    required this.action,
    this.details,
    this.priority,
    this.timeline,
  });

  factory RecommendationAction.fromJson(Map<String, dynamic> json) =>
      _$RecommendationActionFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationActionToJson(this);
}

@JsonSerializable()
class ResourceEstimation {
  @JsonKey(name: 'estimated_time_hours')
  final double? estimatedTimeHours;
  
  @JsonKey(name: 'estimated_cost_range')
  final String? estimatedCostRange;
  
  final String? complexity;

  ResourceEstimation({
    this.estimatedTimeHours,
    this.estimatedCostRange,
    this.complexity,
  });

  factory ResourceEstimation.fromJson(Map<String, dynamic> json) =>
      _$ResourceEstimationFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceEstimationToJson(this);
}

@JsonSerializable()
class LocalizedRecommendations {
  final String? language;
  
  @JsonKey(name: 'regional_context')
  final String? regionalContext;
  
  @JsonKey(name: 'cultural_notes')
  final String? culturalNotes;

  LocalizedRecommendations({
    this.language,
    this.regionalContext,
    this.culturalNotes,
  });

  factory LocalizedRecommendations.fromJson(Map<String, dynamic> json) =>
      _$LocalizedRecommendationsFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedRecommendationsToJson(this);
}
