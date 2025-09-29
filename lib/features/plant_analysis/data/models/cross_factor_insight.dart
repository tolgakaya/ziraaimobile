class CrossFactorInsight {
  final String? insight;
  final double? confidence;
  final List<String>? affectedAspects;
  final String? impactLevel;

  CrossFactorInsight({
    this.insight,
    this.confidence,
    this.affectedAspects,
    this.impactLevel,
  });

  factory CrossFactorInsight.fromJson(Map<String, dynamic> json) {
    return CrossFactorInsight(
      insight: json['insight']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      affectedAspects: (json['affectedAspects'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      impactLevel: json['impactLevel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insight': insight,
      'confidence': confidence,
      'affectedAspects': affectedAspects,
      'impactLevel': impactLevel,
    };
  }
}