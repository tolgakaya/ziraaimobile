class HealthAssessment {
  final int? vigorScore;
  final String? leafColor;
  final String? leafTexture;
  final String? growthPattern;
  final String? structuralIntegrity;
  final String? severity;
  final List<String>? stressIndicators;
  final List<String>? diseaseSymptoms;
  final String? overallCondition;
  final List<String>? symptoms;

  HealthAssessment({
    this.vigorScore,
    this.leafColor,
    this.leafTexture,
    this.growthPattern,
    this.structuralIntegrity,
    this.severity,
    this.stressIndicators,
    this.diseaseSymptoms,
    this.overallCondition,
    this.symptoms,
  });

  factory HealthAssessment.fromJson(Map<String, dynamic> json) {
    return HealthAssessment(
      vigorScore: json['vigorScore'] as int?,
      leafColor: json['leafColor']?.toString(),
      leafTexture: json['leafTexture']?.toString(),
      growthPattern: json['growthPattern']?.toString(),
      structuralIntegrity: json['structuralIntegrity']?.toString(),
      severity: json['severity']?.toString(),
      stressIndicators: (json['stressIndicators'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      diseaseSymptoms: (json['diseaseSymptoms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      overallCondition: json['overallCondition']?.toString(),
      symptoms: (json['symptoms'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vigorScore': vigorScore,
      'leafColor': leafColor,
      'leafTexture': leafTexture,
      'growthPattern': growthPattern,
      'structuralIntegrity': structuralIntegrity,
      'severity': severity,
      'stressIndicators': stressIndicators,
      'diseaseSymptoms': diseaseSymptoms,
      'overallCondition': overallCondition,
      'symptoms': symptoms,
    };
  }
}