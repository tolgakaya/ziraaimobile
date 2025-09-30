class NutrientStatusComplete {
  // Basic nutrients
  final String? nitrogen;
  final String? phosphorus;
  final String? potassium;
  final String? calcium;
  final String? magnesium;
  final String? sulfur;
  
  // Micronutrients
  final String? iron;
  final String? zinc;
  final String? manganese;
  final String? boron;
  final String? copper;
  final String? molybdenum;
  final String? chlorine;
  final String? nickel;
  
  // Status fields
  final String? primaryDeficiency;
  final List<String>? secondaryDeficiencies;
  final String? severity;
  final String? overallStatus;

  NutrientStatusComplete({
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.calcium,
    this.magnesium,
    this.sulfur,
    this.iron,
    this.zinc,
    this.manganese,
    this.boron,
    this.copper,
    this.molybdenum,
    this.chlorine,
    this.nickel,
    this.primaryDeficiency,
    this.secondaryDeficiencies,
    this.severity,
    this.overallStatus,
  });

  factory NutrientStatusComplete.fromJson(Map<String, dynamic> json) {
    return NutrientStatusComplete(
      nitrogen: json['nitrogen']?.toString(),
      phosphorus: json['phosphorus']?.toString(),
      potassium: json['potassium']?.toString(),
      calcium: json['calcium']?.toString(),
      magnesium: json['magnesium']?.toString(),
      sulfur: json['sulfur']?.toString(),
      iron: json['iron']?.toString(),
      zinc: json['zinc']?.toString(),
      manganese: json['manganese']?.toString(),
      boron: json['boron']?.toString(),
      copper: json['copper']?.toString(),
      molybdenum: json['molybdenum']?.toString(),
      chlorine: json['chlorine']?.toString(),
      nickel: json['nickel']?.toString(),
      primaryDeficiency: json['primaryDeficiency']?.toString(),
      secondaryDeficiencies: (json['secondaryDeficiencies'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      severity: json['severity']?.toString(),
      overallStatus: json['overallStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'calcium': calcium,
      'magnesium': magnesium,
      'sulfur': sulfur,
      'iron': iron,
      'zinc': zinc,
      'manganese': manganese,
      'boron': boron,
      'copper': copper,
      'molybdenum': molybdenum,
      'chlorine': chlorine,
      'nickel': nickel,
      'primaryDeficiency': primaryDeficiency,
      'secondaryDeficiencies': secondaryDeficiencies,
      'severity': severity,
      'overallStatus': overallStatus,
    };
  }
}