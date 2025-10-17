import 'package:json_annotation/json_annotation.dart';

part 'nutrient_status.g.dart';

/// Nutrient Status Model
/// Parses the nutrientStatus JSON string from analysis detail
/// Example: {"nitrogen": "eksik", "phosphorus": "normal", "potassium": "eksik"}
@JsonSerializable()
class NutrientStatus {
  final String? nitrogen;
  final String? phosphorus;
  final String? potassium;
  final String? calcium;
  final String? magnesium;
  final String? sulfur;
  final String? iron;
  final String? manganese;
  final String? zinc;
  final String? copper;
  final String? boron;
  final String? molybdenum;

  NutrientStatus({
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.calcium,
    this.magnesium,
    this.sulfur,
    this.iron,
    this.manganese,
    this.zinc,
    this.copper,
    this.boron,
    this.molybdenum,
  });

  factory NutrientStatus.fromJson(Map<String, dynamic> json) =>
      _$NutrientStatusFromJson(json);

  Map<String, dynamic> toJson() => _$NutrientStatusToJson(this);

  /// Get all nutrients with their status
  List<NutrientInfo> getAllNutrients() {
    final nutrients = <NutrientInfo>[];

    void addIfNotNull(String name, String? status, String displayName) {
      if (status != null && status.isNotEmpty) {
        nutrients.add(NutrientInfo(
          name: name,
          displayName: displayName,
          status: status,
        ));
      }
    }

    addIfNotNull('nitrogen', nitrogen, 'Azot (N)');
    addIfNotNull('phosphorus', phosphorus, 'Fosfor (P)');
    addIfNotNull('potassium', potassium, 'Potasyum (K)');
    addIfNotNull('calcium', calcium, 'Kalsiyum (Ca)');
    addIfNotNull('magnesium', magnesium, 'Magnezyum (Mg)');
    addIfNotNull('sulfur', sulfur, 'Kükürt (S)');
    addIfNotNull('iron', iron, 'Demir (Fe)');
    addIfNotNull('manganese', manganese, 'Mangan (Mn)');
    addIfNotNull('zinc', zinc, 'Çinko (Zn)');
    addIfNotNull('copper', copper, 'Bakır (Cu)');
    addIfNotNull('boron', boron, 'Bor (B)');
    addIfNotNull('molybdenum', molybdenum, 'Molibden (Mo)');

    return nutrients;
  }
}

/// Nutrient information for display
class NutrientInfo {
  final String name;
  final String displayName;
  final String status;

  NutrientInfo({
    required this.name,
    required this.displayName,
    required this.status,
  });

  /// Get status level (eksik, düşük, normal, yüksek, fazla)
  NutrientLevel get level {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('eksik') || statusLower == 'deficient') {
      return NutrientLevel.deficient;
    } else if (statusLower.contains('düşük') || statusLower == 'low') {
      return NutrientLevel.low;
    } else if (statusLower.contains('normal') || statusLower == 'optimal') {
      return NutrientLevel.normal;
    } else if (statusLower.contains('yüksek') || statusLower == 'high') {
      return NutrientLevel.high;
    } else if (statusLower.contains('fazla') || statusLower == 'excessive') {
      return NutrientLevel.excessive;
    }
    return NutrientLevel.unknown;
  }

  /// Get display text for status
  String get displayStatus {
    switch (level) {
      case NutrientLevel.deficient:
        return 'Eksik';
      case NutrientLevel.low:
        return 'Düşük';
      case NutrientLevel.normal:
        return 'Normal';
      case NutrientLevel.high:
        return 'Yüksek';
      case NutrientLevel.excessive:
        return 'Fazla';
      case NutrientLevel.unknown:
        return status;
    }
  }
}

/// Nutrient level enum
enum NutrientLevel {
  deficient,
  low,
  normal,
  high,
  excessive,
  unknown,
}
