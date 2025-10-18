import 'plant_disease.dart';
import 'plant_treatment.dart';
import 'plant_identification.dart';
import 'health_assessment.dart';
import 'nutrient_status.dart';
import 'pest_disease.dart';
import 'recommendations.dart';
import 'analysis_summary.dart';
import 'environmental_factors.dart';

class PlantAnalysisResult {
  final int? id;
  final String? analysisId;
  final DateTime? analysisDate;
  final String? analysisStatus;
  final int? userId;
  final String? farmerId;
  final int? sponsorId;
  final String? sponsorName;
  final String? location;
  final String? cropType;
  final List<String>? previousTreatments;
  final String? notes;
  final PlantIdentification? plantIdentification;
  final HealthAssessment? healthAssessment;
  final List<PlantDisease>? diseases;
  final List<PlantTreatment>? treatments;
  final List<String>? recommendations;
  final String? imageUrl;
  final Map<String, dynamic>? additionalData;
  
  // New comprehensive fields
  final NutrientStatus? nutrientStatus;
  final PestDisease? pestDisease;
  final Recommendations? recommendationsDetailed;
  final AnalysisSummary? summary;
  final EnvironmentalFactors? environmentalFactors;
  final String? imagePath;
  final String? analysisModel;
  final String? modelVersion;
  final DateTime? createdDate;
  final String? plantSpecies;

  PlantAnalysisResult({
    this.id,
    this.analysisId,
    this.analysisDate,
    this.analysisStatus,
    this.userId,
    this.farmerId,
    this.sponsorId,
    this.sponsorName,
    this.location,
    this.cropType,
    this.previousTreatments,
    this.notes,
    this.plantIdentification,
    this.healthAssessment,
    this.diseases,
    this.treatments,
    this.recommendations,
    this.imageUrl,
    this.additionalData,
    this.nutrientStatus,
    this.pestDisease,
    this.recommendationsDetailed,
    this.summary,
    this.environmentalFactors,
    this.imagePath,
    this.analysisModel,
    this.modelVersion,
    this.createdDate,
    this.plantSpecies,
  });

  factory PlantAnalysisResult.fromJson(Map<String, dynamic> json) {
    return PlantAnalysisResult(
      id: json['id'] as int?,
      analysisId: json['analysisId'] as String?,
      analysisDate: json['analysisDate'] != null
          ? DateTime.tryParse(json['analysisDate'] as String)
          : null,
      analysisStatus: json['analysisStatus'] as String?,
      userId: json['userId'] as int?,
      farmerId: json['farmerId'] as String?,
      sponsorId: json['sponsorId'] as int?,
      sponsorName: json['sponsorName'] as String?,
      location: json['location'] as String?,
      cropType: json['cropType'] as String?,
      previousTreatments: (json['previousTreatments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
      plantIdentification: json['plantIdentification'] != null
          ? PlantIdentification.fromJson(json['plantIdentification'] as Map<String, dynamic>)
          : null,
      healthAssessment: json['healthAssessment'] != null
          ? HealthAssessment.fromJson(json['healthAssessment'] as Map<String, dynamic>)
          : null,
      diseases: (json['diseases'] as List<dynamic>?)
          ?.map((e) => PlantDisease.fromJson(e as Map<String, dynamic>))
          .toList(),
      treatments: (json['treatments'] as List<dynamic>?)
          ?.map((e) => PlantTreatment.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      
      // New comprehensive fields
      nutrientStatus: json['nutrientStatus'] != null
          ? NutrientStatus.fromJson(json['nutrientStatus'] as Map<String, dynamic>)
          : null,
      pestDisease: json['pestDisease'] != null
          ? PestDisease.fromJson(json['pestDisease'] as Map<String, dynamic>)
          : null,
      recommendationsDetailed: json['recommendations'] != null && json['recommendations'] is Map
          ? Recommendations.fromJson(json['recommendations'] as Map<String, dynamic>)
          : null,
      summary: json['summary'] != null
          ? AnalysisSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
      environmentalFactors: json['environmentalFactors'] != null
          ? EnvironmentalFactors.fromJson(json['environmentalFactors'] as Map<String, dynamic>)
          : null,
      imagePath: json['imagePath'] as String?,
      analysisModel: json['analysisModel'] as String?,
      modelVersion: json['modelVersion'] as String?,
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
      plantSpecies: json['plantSpecies'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'analysisId': analysisId,
      'analysisDate': analysisDate?.toIso8601String(),
      'analysisStatus': analysisStatus,
      'userId': userId,
      'farmerId': farmerId,
      'sponsorId': sponsorId,
      'sponsorName': sponsorName,
      'location': location,
      'cropType': cropType,
      'previousTreatments': previousTreatments,
      'notes': notes,
      'plantIdentification': plantIdentification?.toJson(),
      'healthAssessment': healthAssessment?.toJson(),
      'diseases': diseases?.map((e) => e.toJson()).toList(),
      'treatments': treatments?.map((e) => e.toJson()).toList(),
      'recommendations': recommendations,
      'imageUrl': imageUrl,
      'additionalData': additionalData,
      'nutrientStatus': nutrientStatus?.toJson(),
      'pestDisease': pestDisease?.toJson(),
      'recommendationsDetailed': recommendationsDetailed?.toJson(),
      'summary': summary?.toJson(),
      'environmentalFactors': environmentalFactors?.toJson(),
      'imagePath': imagePath,
      'analysisModel': analysisModel,
      'modelVersion': modelVersion,
      'createdDate': createdDate?.toIso8601String(),
      'plantSpecies': plantSpecies,
    };
  }

  // Convenience getters for backward compatibility
  String get species => plantIdentification?.species ?? cropType ?? plantSpecies ?? 'Bilinmeyen Bitki';
  String get status => analysisStatus ?? 'Unknown';
  double? get confidence => plantIdentification?.confidence;
  String get healthStatus => healthAssessment?.severity ?? summary?.overallHealthScore ?? 'Unknown';
  String? get growthStage => plantIdentification?.growthStage;
  String get finalImageUrl => imageUrl ?? imagePath ?? '';
}