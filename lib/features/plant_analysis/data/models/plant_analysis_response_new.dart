import 'package:json_annotation/json_annotation.dart';

part 'plant_analysis_response_new.g.dart';

/// Response model for Plant Analysis API async submission
@JsonSerializable()
class PlantAnalysisAsyncResponse {
  @JsonKey(name: 'analysisId')
  final String analysisId;
  final String status;
  @JsonKey(name: 'estimatedTime')
  final String? estimatedTime;
  @JsonKey(name: 'queuePosition')
  final int? queuePosition;

  const PlantAnalysisAsyncResponse({
    required this.analysisId,
    required this.status,
    this.estimatedTime,
    this.queuePosition,
  });

  factory PlantAnalysisAsyncResponse.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisAsyncResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisAsyncResponseToJson(this);

  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  @override
  String toString() {
    return 'PlantAnalysisAsyncResponse(analysisId: $analysisId, status: $status)';
  }
}

/// Real API response model based on actual backend
@JsonSerializable()
class PlantAnalysisResult {
  /// Database primary key ID
  final int id;

  /// Image path/URL
  @JsonKey(name: 'imagePath')
  final String? imagePath;

  /// Analysis completion timestamp
  @JsonKey(name: 'analysisDate')
  final String analysisDate;

  /// Analysis status
  final String status;

  /// User ID
  @JsonKey(name: 'userId')
  final int userId;

  /// String analysis ID
  @JsonKey(name: 'analysisId')
  final String analysisId;

  /// Farmer ID
  @JsonKey(name: 'farmerId')
  final String? farmerId;

  /// Location
  final String? location;

  /// Crop type
  @JsonKey(name: 'cropType')
  final String? cropType;

  /// Analysis notes
  final String? notes;

  /// Plant type
  @JsonKey(name: 'plantType')
  final String? plantType;

  /// Growth stage
  @JsonKey(name: 'growthStage')
  final String? growthStage;

  /// Element deficiencies
  @JsonKey(name: 'elementDeficiencies')
  final List<ElementDeficiency> elementDeficiencies;

  /// Detected diseases
  final List<PlantDisease> diseases;

  /// Detected pests
  final List<PlantPest> pests;

  const PlantAnalysisResult({
    required this.id,
    this.imagePath,
    required this.analysisDate,
    required this.status,
    required this.userId,
    required this.analysisId,
    this.farmerId,
    this.location,
    this.cropType,
    this.notes,
    this.plantType,
    this.growthStage,
    required this.elementDeficiencies,
    required this.diseases,
    required this.pests,
  });

  factory PlantAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$PlantAnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$PlantAnalysisResultToJson(this);

  /// Check if analysis is completed successfully
  bool get isSuccessful => status.toLowerCase() == 'completed';

  /// Get confidence score (calculated from deficiencies and diseases)
  double get confidence {
    if (elementDeficiencies.isEmpty && diseases.isEmpty && pests.isEmpty) {
      return 95.0; // Healthy plant
    }

    // Calculate based on severity of issues
    double totalSeverity = 0.0;
    int issueCount = 0;

    for (final deficiency in elementDeficiencies) {
      switch (deficiency.severity.toLowerCase()) {
        case 'high':
          totalSeverity += 30.0;
          break;
        case 'medium':
          totalSeverity += 20.0;
          break;
        case 'low':
          totalSeverity += 10.0;
          break;
      }
      issueCount++;
    }

    for (final disease in diseases) {
      switch (disease.severity.toLowerCase()) {
        case 'high':
          totalSeverity += 40.0;
          break;
        case 'medium':
          totalSeverity += 25.0;
          break;
        case 'low':
          totalSeverity += 15.0;
          break;
      }
      issueCount++;
    }

    if (issueCount == 0) return 95.0;

    double avgSeverity = totalSeverity / issueCount;
    return (100.0 - avgSeverity).clamp(10.0, 95.0);
  }

  /// Get all treatments (from deficiencies and diseases)
  List<PlantTreatment> get treatments {
    List<PlantTreatment> allTreatments = [];

    // Convert element deficiencies to treatments
    for (final deficiency in elementDeficiencies) {
      allTreatments.add(PlantTreatment(
        name: '${deficiency.element.toUpperCase()} Eksikliği Tedavisi',
        type: 'Chemical',
        instructions: deficiency.treatment ?? 'Detaylı önerilere bakınız',
        frequency: _getDeficiencyFrequency(deficiency.severity),
        category: 'nutrient',
      ));
    }

    return allTreatments;
  }

  String _getDeficiencyFrequency(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'Haftada 2 kez';
      case 'medium':
        return 'Haftada 1 kez';
      case 'low':
        return '15 günde 1 kez';
      default:
        return 'Gerektiği kadar';
    }
  }

  @override
  String toString() {
    return 'PlantAnalysisResult(id: $id, status: $status, plantType: $plantType)';
  }
}

/// Element deficiency model
@JsonSerializable()
class ElementDeficiency {
  final String element;
  final String severity;
  final String description;
  final String? treatment;

  const ElementDeficiency({
    required this.element,
    required this.severity,
    required this.description,
    this.treatment,
  });

  factory ElementDeficiency.fromJson(Map<String, dynamic> json) =>
      _$ElementDeficiencyFromJson(json);

  Map<String, dynamic> toJson() => _$ElementDeficiencyToJson(this);

  @override
  String toString() {
    return 'ElementDeficiency(element: $element, severity: $severity)';
  }
}

/// Plant disease model (updated for real API)
@JsonSerializable()
class PlantDisease {
  final String name;
  final String severity;
  final double confidence;
  final String? description;
  final String? category;

  const PlantDisease({
    required this.name,
    required this.severity,
    required this.confidence,
    this.description,
    this.category,
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) =>
      _$PlantDiseaseFromJson(json);

  Map<String, dynamic> toJson() => _$PlantDiseaseToJson(this);

  bool get isHighSeverity => severity.toLowerCase() == 'high';

  String get severityColor {
    switch (severity.toLowerCase()) {
      case 'high':
        return '#FF5252';
      case 'medium':
        return '#FF9800';
      case 'low':
        return '#4CAF50';
      default:
        return '#757575';
    }
  }

  @override
  String toString() {
    return 'PlantDisease(name: $name, severity: $severity, confidence: $confidence)';
  }
}

/// Plant pest model
@JsonSerializable()
class PlantPest {
  final String name;
  final String severity;
  final double? confidence;
  final String? description;

  const PlantPest({
    required this.name,
    required this.severity,
    this.confidence,
    this.description,
  });

  factory PlantPest.fromJson(Map<String, dynamic> json) =>
      _$PlantPestFromJson(json);

  Map<String, dynamic> toJson() => _$PlantPestToJson(this);

  @override
  String toString() {
    return 'PlantPest(name: $name, severity: $severity)';
  }
}

/// Treatment recommendation model (updated)
@JsonSerializable()
class PlantTreatment {
  final String name;
  final String type;
  final String instructions;
  final String? frequency;
  final String? category;

  const PlantTreatment({
    required this.name,
    required this.type,
    required this.instructions,
    this.frequency,
    this.category,
  });

  factory PlantTreatment.fromJson(Map<String, dynamic> json) =>
      _$PlantTreatmentFromJson(json);

  Map<String, dynamic> toJson() => _$PlantTreatmentToJson(this);

  bool get isOrganic => type.toLowerCase().contains('organic');

  String get treatmentIcon {
    if (isOrganic) return '🌿';
    if (type.toLowerCase().contains('chemical')) return '🧪';
    return '🔧';
  }

  @override
  String toString() {
    return 'PlantTreatment(name: $name, type: $type)';
  }
}