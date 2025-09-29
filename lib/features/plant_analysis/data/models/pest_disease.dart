class PestDisease {
  final String? overallStatus;
  final List<DiseaseDetected>? diseasesDetected;
  final List<PestDetected>? pestsDetected;
  final String? preventiveMeasures;

  PestDisease({
    this.overallStatus,
    this.diseasesDetected,
    this.pestsDetected,
    this.preventiveMeasures,
  });

  factory PestDisease.fromJson(Map<String, dynamic> json) {
    return PestDisease(
      overallStatus: json['overallStatus']?.toString(),
      diseasesDetected: (json['diseasesDetected'] as List<dynamic>?)
          ?.map((e) => DiseaseDetected.fromJson(e as Map<String, dynamic>))
          .toList(),
      pestsDetected: (json['pestsDetected'] as List<dynamic>?)
          ?.map((e) => PestDetected.fromJson(e as Map<String, dynamic>))
          .toList(),
      preventiveMeasures: json['preventiveMeasures']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallStatus': overallStatus,
      'diseasesDetected': diseasesDetected?.map((e) => e.toJson()).toList(),
      'pestsDetected': pestsDetected?.map((e) => e.toJson()).toList(),
      'preventiveMeasures': preventiveMeasures,
    };
  }
}

class DiseaseDetected {
  final String? type;
  final String? severity;
  final double? confidence;
  final String? category;
  final List<String>? affectedParts;
  final String? description;

  DiseaseDetected({
    this.type,
    this.severity,
    this.confidence,
    this.category,
    this.affectedParts,
    this.description,
  });

  factory DiseaseDetected.fromJson(Map<String, dynamic> json) {
    return DiseaseDetected(
      type: json['type']?.toString() ?? json['name']?.toString(),
      severity: json['severity']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      category: json['category']?.toString(),
      affectedParts: (json['affectedParts'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'severity': severity,
      'confidence': confidence,
      'category': category,
      'affectedParts': affectedParts,
      'description': description,
    };
  }
}

class PestDetected {
  final String? type;
  final String? severity;
  final double? confidence;
  final List<String>? affectedParts;
  final String? description;

  PestDetected({
    this.type,
    this.severity,
    this.confidence,
    this.affectedParts,
    this.description,
  });

  factory PestDetected.fromJson(Map<String, dynamic> json) {
    return PestDetected(
      type: json['type']?.toString() ?? json['name']?.toString(),
      severity: json['severity']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      affectedParts: (json['affectedParts'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'severity': severity,
      'confidence': confidence,
      'affectedParts': affectedParts,
      'description': description,
    };
  }
}