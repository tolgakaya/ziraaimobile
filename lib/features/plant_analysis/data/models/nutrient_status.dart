class NutrientStatus {
  final String? overallStatus;
  final List<String>? deficiencies;
  final List<String>? excesses;
  final List<NutrientDetail>? details;

  NutrientStatus({
    this.overallStatus,
    this.deficiencies,
    this.excesses,
    this.details,
  });

  factory NutrientStatus.fromJson(Map<String, dynamic> json) {
    return NutrientStatus(
      overallStatus: json['overallStatus']?.toString(),
      deficiencies: (json['deficiencies'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      excesses: (json['excesses'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => NutrientDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallStatus': overallStatus,
      'deficiencies': deficiencies,
      'excesses': excesses,
      'details': details?.map((e) => e.toJson()).toList(),
    };
  }
}

class NutrientDetail {
  final String? name;
  final String? status;
  final String? level;
  final String? recommendation;

  NutrientDetail({
    this.name,
    this.status,
    this.level,
    this.recommendation,
  });

  factory NutrientDetail.fromJson(Map<String, dynamic> json) {
    return NutrientDetail(
      name: json['name']?.toString(),
      status: json['status']?.toString(),
      level: json['level']?.toString(),
      recommendation: json['recommendation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'level': level,
      'recommendation': recommendation,
    };
  }
}