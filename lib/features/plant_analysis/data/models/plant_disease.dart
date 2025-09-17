class PlantDisease {
  final String? name;
  final String? severity;
  final double? confidence;
  final String? description;
  final List<String>? symptoms;
  final List<String>? affectedParts;
  final String? category;

  PlantDisease({
    this.name,
    this.severity,
    this.confidence,
    this.description,
    this.symptoms,
    this.affectedParts,
    this.category,
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    return PlantDisease(
      name: json['name'] as String?,
      severity: json['severity'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      description: json['description'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      affectedParts: (json['affectedParts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'confidence': confidence,
      'description': description,
      'symptoms': symptoms,
      'affectedParts': affectedParts,
      'category': category,
    };
  }
}