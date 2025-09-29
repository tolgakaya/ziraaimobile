class PlantIdentification {
  final String? species;
  final String? variety;
  final String? growthStage;
  final double? confidence;
  final List<String>? identifyingFeatures;
  final List<String>? visibleParts;
  final String? commonName;
  final String? scientificName;

  PlantIdentification({
    this.species,
    this.variety,
    this.growthStage,
    this.confidence,
    this.identifyingFeatures,
    this.visibleParts,
    this.commonName,
    this.scientificName,
  });

  factory PlantIdentification.fromJson(Map<String, dynamic> json) {
    return PlantIdentification(
      species: json['species']?.toString(),
      variety: json['variety']?.toString(),
      growthStage: json['growthStage']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      identifyingFeatures: (json['identifyingFeatures'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      visibleParts: (json['visibleParts'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      commonName: json['commonName']?.toString(),
      scientificName: json['scientificName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'variety': variety,
      'growthStage': growthStage,
      'confidence': confidence,
      'identifyingFeatures': identifyingFeatures,
      'visibleParts': visibleParts,
      'commonName': commonName,
      'scientificName': scientificName,
    };
  }
}