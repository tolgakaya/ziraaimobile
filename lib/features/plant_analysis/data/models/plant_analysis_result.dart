import 'plant_disease.dart';
import 'plant_treatment.dart';

class PlantAnalysisResult {
  final String analysisId;
  final String? plantSpecies;
  final String? status;
  final double? confidence;
  final String? imageUrl;
  final String? healthStatus;
  final String? growthStage;
  final String? environmentalConditions;
  final List<PlantDisease>? diseases;
  final List<PlantTreatment>? treatments;
  final List<String>? recommendations;
  final DateTime? createdDate;
  final Map<String, dynamic>? additionalData;

  PlantAnalysisResult({
    required this.analysisId,
    this.plantSpecies,
    this.status,
    this.confidence,
    this.imageUrl,
    this.healthStatus,
    this.growthStage,
    this.environmentalConditions,
    this.diseases,
    this.treatments,
    this.recommendations,
    this.createdDate,
    this.additionalData,
  });

  factory PlantAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PlantAnalysisResult(
      analysisId: json['analysisId'] ?? json['id'] ?? '',
      plantSpecies: json['plantSpecies'] as String?,
      status: json['status'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      healthStatus: json['healthStatus'] as String?,
      growthStage: json['growthStage'] as String?,
      environmentalConditions: json['environmentalConditions'] as String?,
      diseases: (json['diseases'] as List<dynamic>?)
          ?.map((e) => PlantDisease.fromJson(e as Map<String, dynamic>))
          .toList(),
      treatments: (json['treatments'] as List<dynamic>?)
          ?.map((e) => PlantTreatment.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysisId': analysisId,
      'plantSpecies': plantSpecies,
      'status': status,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'healthStatus': healthStatus,
      'growthStage': growthStage,
      'environmentalConditions': environmentalConditions,
      'diseases': diseases?.map((e) => e.toJson()).toList(),
      'treatments': treatments?.map((e) => e.toJson()).toList(),
      'recommendations': recommendations,
      'createdDate': createdDate?.toIso8601String(),
      'additionalData': additionalData,
    };
  }
}