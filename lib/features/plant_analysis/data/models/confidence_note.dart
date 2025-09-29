class ConfidenceNote {
  final String? aspect;
  final double? confidence;
  final String? reason;

  ConfidenceNote({
    this.aspect,
    this.confidence,
    this.reason,
  });

  factory ConfidenceNote.fromJson(Map<String, dynamic> json) {
    return ConfidenceNote(
      aspect: json['aspect']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aspect': aspect,
      'confidence': confidence,
      'reason': reason,
    };
  }
}