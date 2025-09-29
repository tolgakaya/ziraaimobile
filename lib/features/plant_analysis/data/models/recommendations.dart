class Recommendations {
  final List<RecommendationItem>? immediate;
  final List<RecommendationItem>? shortTerm;
  final List<RecommendationItem>? longTerm;
  final List<String>? general;

  Recommendations({
    this.immediate,
    this.shortTerm,
    this.longTerm,
    this.general,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    return Recommendations(
      immediate: (json['immediate'] as List<dynamic>?)
          ?.map((e) => RecommendationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shortTerm: (json['shortTerm'] as List<dynamic>?)
          ?.map((e) => RecommendationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      longTerm: (json['longTerm'] as List<dynamic>?)
          ?.map((e) => RecommendationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      general: (json['general'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'immediate': immediate?.map((e) => e.toJson()).toList(),
      'shortTerm': shortTerm?.map((e) => e.toJson()).toList(),
      'longTerm': longTerm?.map((e) => e.toJson()).toList(),
      'general': general,
    };
  }
}

class RecommendationItem {
  final String? action;
  final String? details;
  final String? priority;
  final String? category;
  final String? timeline;
  final String? expectedOutcome;

  RecommendationItem({
    this.action,
    this.details,
    this.priority,
    this.category,
    this.timeline,
    this.expectedOutcome,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      action: json['action']?.toString(),
      details: json['details']?.toString(),
      priority: json['priority']?.toString(),
      category: json['category']?.toString(),
      timeline: json['timeline']?.toString(),
      expectedOutcome: json['expectedOutcome']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'details': details,
      'priority': priority,
      'category': category,
      'timeline': timeline,
      'expectedOutcome': expectedOutcome,
    };
  }
}