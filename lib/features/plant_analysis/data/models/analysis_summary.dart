class AnalysisSummary {
  final String? primaryConcern;
  final String? overallHealthScore;
  final List<String>? keyFindings;
  final List<String>? secondaryConcerns;
  final String? confidenceLevel;
  final String? urgencyLevel;

  AnalysisSummary({
    this.primaryConcern,
    this.overallHealthScore,
    this.keyFindings,
    this.secondaryConcerns,
    this.confidenceLevel,
    this.urgencyLevel,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      primaryConcern: json['primaryConcern']?.toString(),
      overallHealthScore: json['overallHealthScore']?.toString(),
      keyFindings: (json['keyFindings'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      secondaryConcerns: (json['secondaryConcerns'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      confidenceLevel: json['confidenceLevel']?.toString(),
      urgencyLevel: json['urgencyLevel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryConcern': primaryConcern,
      'overallHealthScore': overallHealthScore,
      'keyFindings': keyFindings,
      'secondaryConcerns': secondaryConcerns,
      'confidenceLevel': confidenceLevel,
      'urgencyLevel': urgencyLevel,
    };
  }
}