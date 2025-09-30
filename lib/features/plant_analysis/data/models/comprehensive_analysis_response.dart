import 'package:json_annotation/json_annotation.dart';

part 'comprehensive_analysis_response.g.dart';

/// Comprehensive Plant Analysis Response with all 10 sections
@JsonSerializable()
class ComprehensiveAnalysisResponse {
  final PlantIdentificationComplete? plantIdentification;
  final HealthAssessmentComplete? healthAssessment;
  final NutrientStatusExtended? nutrientStatus;
  final PestDiseaseComplete? pestDisease;
  final EnvironmentalStressComplete? environmentalStress;
  final AnalysisSummaryComplete? summary;
  final CrossFactorInsights? crossFactorInsights;
  final RecommendationsComplete? recommendations;
  final List<ConfidenceNote>? confidenceNotes;
  final FarmerFriendlySummary? farmerFriendlySummary;

  const ComprehensiveAnalysisResponse({
    this.plantIdentification,
    this.healthAssessment,
    this.nutrientStatus,
    this.pestDisease,
    this.environmentalStress,
    this.summary,
    this.crossFactorInsights,
    this.recommendations,
    this.confidenceNotes,
    this.farmerFriendlySummary,
  });

  factory ComprehensiveAnalysisResponse.fromJson(Map<String, dynamic> json) =>
      _$ComprehensiveAnalysisResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComprehensiveAnalysisResponseToJson(this);
}

/// 1. Plant Identification (Complete with all 6 fields)
@JsonSerializable()
class PlantIdentificationComplete {
  final String? plantSpecies;
  final String? commonName;
  final String? scientificName;
  final String? variety;
  final List<String>? identifyingFeatures;
  final List<String>? visibleParts;

  const PlantIdentificationComplete({
    this.plantSpecies,
    this.commonName,
    this.scientificName,
    this.variety,
    this.identifyingFeatures,
    this.visibleParts,
  });

  factory PlantIdentificationComplete.fromJson(Map<String, dynamic> json) =>
      _$PlantIdentificationCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$PlantIdentificationCompleteToJson(this);
}

/// 2. Health Assessment (Complete with all 8 fields)
@JsonSerializable()
class HealthAssessmentComplete {
  final String? overallHealthScore;
  final String? overallCondition;
  final String? primaryConcern;
  final String? secondaryConcerns;
  final List<String>? symptoms;
  final List<String>? diseaseSymptoms;
  final String? growthStage;
  final String? physicalCondition;

  const HealthAssessmentComplete({
    this.overallHealthScore,
    this.overallCondition,
    this.primaryConcern,
    this.secondaryConcerns,
    this.symptoms,
    this.diseaseSymptoms,
    this.growthStage,
    this.physicalCondition,
  });

  factory HealthAssessmentComplete.fromJson(Map<String, dynamic> json) =>
      _$HealthAssessmentCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$HealthAssessmentCompleteToJson(this);
}

/// 3. Nutrient Status Extended (with all 14 nutrients)
@JsonSerializable()
class NutrientStatusExtended {
  final String? overallStatus;
  final String? primaryDeficiency;
  final List<String>? secondaryDeficiencies;
  final String? severity;
  
  // All 14 nutrients
  final String? nitrogen;
  final String? phosphorus;
  final String? potassium;
  final String? calcium;
  final String? magnesium;
  final String? sulfur;
  final String? iron;
  final String? manganese;
  final String? zinc;
  final String? copper;
  final String? boron;
  final String? molybdenum;
  final String? chlorine;
  final String? nickel;

  final List<String>? deficiencies;
  final List<String>? excesses;
  final List<NutrientDetail>? details;

  const NutrientStatusExtended({
    this.overallStatus,
    this.primaryDeficiency,
    this.secondaryDeficiencies,
    this.severity,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.calcium,
    this.magnesium,
    this.sulfur,
    this.iron,
    this.manganese,
    this.zinc,
    this.copper,
    this.boron,
    this.molybdenum,
    this.chlorine,
    this.nickel,
    this.deficiencies,
    this.excesses,
    this.details,
  });

  factory NutrientStatusExtended.fromJson(Map<String, dynamic> json) =>
      _$NutrientStatusExtendedFromJson(json);

  Map<String, dynamic> toJson() => _$NutrientStatusExtendedToJson(this);
}

/// 4. Pest & Disease Complete 
@JsonSerializable()
class PestDiseaseComplete {
  final String? overallStatus;
  final List<DiseaseDetectedComplete>? diseasesDetected;
  final List<PestDetectedComplete>? pestsDetected;
  final String? preventiveMeasures;
  final String? damagePattern;
  final String? affectedAreaPercentage;
  final String? spreadRisk;

  const PestDiseaseComplete({
    this.overallStatus,
    this.diseasesDetected,
    this.pestsDetected,
    this.preventiveMeasures,
    this.damagePattern,
    this.affectedAreaPercentage,
    this.spreadRisk,
  });

  factory PestDiseaseComplete.fromJson(Map<String, dynamic> json) =>
      _$PestDiseaseCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$PestDiseaseCompleteToJson(this);
}

@JsonSerializable()
class DiseaseDetectedComplete {
  final String? type;
  final String? severity;
  final double? confidence;
  final String? category;
  final List<String>? affectedParts;
  final String? description;

  const DiseaseDetectedComplete({
    this.type,
    this.severity,
    this.confidence,
    this.category,
    this.affectedParts,
    this.description,
  });

  factory DiseaseDetectedComplete.fromJson(Map<String, dynamic> json) =>
      _$DiseaseDetectedCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$DiseaseDetectedCompleteToJson(this);
}

@JsonSerializable()
class PestDetectedComplete {
  final String? type;
  final String? severity;
  final double? confidence;
  final List<String>? affectedParts;
  final String? description;

  const PestDetectedComplete({
    this.type,
    this.severity,
    this.confidence,
    this.affectedParts,
    this.description,
  });

  factory PestDetectedComplete.fromJson(Map<String, dynamic> json) =>
      _$PestDetectedCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$PestDetectedCompleteToJson(this);
}

/// 5. Environmental Stress Complete (all 6 factors + primaryStressor)
@JsonSerializable()
class EnvironmentalStressComplete {
  final String? lightConditions;
  final String? wateringStatus;
  final String? soilCondition;
  final String? temperature;
  final String? humidity;
  final String? airCirculation;
  final String? primaryStressor;
  final List<String>? stressFactors;

  const EnvironmentalStressComplete({
    this.lightConditions,
    this.wateringStatus,
    this.soilCondition,
    this.temperature,
    this.humidity,
    this.airCirculation,
    this.primaryStressor,
    this.stressFactors,
  });

  factory EnvironmentalStressComplete.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalStressCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$EnvironmentalStressCompleteToJson(this);
}

/// 6. Summary Complete (with prognosis and yield impact)
@JsonSerializable()
class AnalysisSummaryComplete {
  final String? primaryConcern;
  final String? overallHealthScore;
  final String? recommendedAction;
  final String? urgencyLevel;
  final String? prognosis;
  final String? estimatedYieldImpact;

  const AnalysisSummaryComplete({
    this.primaryConcern,
    this.overallHealthScore,
    this.recommendedAction,
    this.urgencyLevel,
    this.prognosis,
    this.estimatedYieldImpact,
  });

  factory AnalysisSummaryComplete.fromJson(Map<String, dynamic> json) =>
      _$AnalysisSummaryCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisSummaryCompleteToJson(this);
}

/// 7. Cross Factor Insights
@JsonSerializable()
class CrossFactorInsights {
  final double? confidence;
  final List<String>? affectedAspects;
  final String? impactLevel;
  final String? primaryInteraction;
  final String? secondaryEffects;

  const CrossFactorInsights({
    this.confidence,
    this.affectedAspects,
    this.impactLevel,
    this.primaryInteraction,
    this.secondaryEffects,
  });

  factory CrossFactorInsights.fromJson(Map<String, dynamic> json) =>
      _$CrossFactorInsightsFromJson(json);

  Map<String, dynamic> toJson() => _$CrossFactorInsightsToJson(this);
}

/// 8. Recommendations Complete (immediate, shortTerm, preventive, monitoring, resource estimation)
@JsonSerializable()
class RecommendationsComplete {
  final List<RecommendationItemComplete>? immediate;
  final List<RecommendationItemComplete>? shortTerm;
  final List<RecommendationItemComplete>? preventive;
  final List<RecommendationItemComplete>? monitoring;
  final List<String>? general;
  final ResourceEstimation? resourceEstimation;

  const RecommendationsComplete({
    this.immediate,
    this.shortTerm,
    this.preventive,
    this.monitoring,
    this.general,
    this.resourceEstimation,
  });

  factory RecommendationsComplete.fromJson(Map<String, dynamic> json) =>
      _$RecommendationsCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationsCompleteToJson(this);
}

@JsonSerializable()
class RecommendationItemComplete {
  final String? action;
  final String? details;
  final String? priority;
  final String? category;
  final String? timeline;
  final String? expectedOutcome;

  const RecommendationItemComplete({
    this.action,
    this.details,
    this.priority,
    this.category,
    this.timeline,
    this.expectedOutcome,
  });

  factory RecommendationItemComplete.fromJson(Map<String, dynamic> json) =>
      _$RecommendationItemCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$RecommendationItemCompleteToJson(this);
}

@JsonSerializable()
class ResourceEstimation {
  final String? timeDuration;
  final String? costEstimate;
  final List<String>? requiredMaterials;
  final String? laborRequirement;

  const ResourceEstimation({
    this.timeDuration,
    this.costEstimate,
    this.requiredMaterials,
    this.laborRequirement,
  });

  factory ResourceEstimation.fromJson(Map<String, dynamic> json) =>
      _$ResourceEstimationFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceEstimationToJson(this);
}

/// 9. Confidence Notes
@JsonSerializable()
class ConfidenceNote {
  final String? aspect;
  final double? confidence;
  final String? reason;

  const ConfidenceNote({
    this.aspect,
    this.confidence,
    this.reason,
  });

  factory ConfidenceNote.fromJson(Map<String, dynamic> json) =>
      _$ConfidenceNoteFromJson(json);

  Map<String, dynamic> toJson() => _$ConfidenceNoteToJson(this);
}

/// 10. Farmer Friendly Summary (must be shown at top)
@JsonSerializable()
class FarmerFriendlySummary {
  final String? simpleExplanation;
  final String? actionNeeded;
  final String? timeframe;
  final String? severity;
  final String? expectedOutcome;

  const FarmerFriendlySummary({
    this.simpleExplanation,
    this.actionNeeded,
    this.timeframe,
    this.severity,
    this.expectedOutcome,
  });

  factory FarmerFriendlySummary.fromJson(Map<String, dynamic> json) =>
      _$FarmerFriendlySummaryFromJson(json);

  Map<String, dynamic> toJson() => _$FarmerFriendlySummaryToJson(this);
}

/// Nutrient Detail (supporting model)
@JsonSerializable()
class NutrientDetail {
  final String? name;
  final String? status;
  final String? level;
  final String? recommendation;

  const NutrientDetail({
    this.name,
    this.status,
    this.level,
    this.recommendation,
  });

  factory NutrientDetail.fromJson(Map<String, dynamic> json) =>
      _$NutrientDetailFromJson(json);

  Map<String, dynamic> toJson() => _$NutrientDetailToJson(this);
}