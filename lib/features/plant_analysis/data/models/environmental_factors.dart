class EnvironmentalFactors {
  final String? lightConditions;
  final String? wateringStatus;
  final String? soilCondition;
  final String? temperature;
  final String? humidity;
  final String? airCirculation;
  final List<String>? stressFactors;

  EnvironmentalFactors({
    this.lightConditions,
    this.wateringStatus,
    this.soilCondition,
    this.temperature,
    this.humidity,
    this.airCirculation,
    this.stressFactors,
  });

  factory EnvironmentalFactors.fromJson(Map<String, dynamic> json) {
    return EnvironmentalFactors(
      lightConditions: json['lightConditions']?.toString(),
      wateringStatus: json['wateringStatus']?.toString(),
      soilCondition: json['soilCondition']?.toString(),
      temperature: json['temperature']?.toString(),
      humidity: json['humidity']?.toString(),
      airCirculation: json['airCirculation']?.toString(),
      stressFactors: (json['stressFactors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lightConditions': lightConditions,
      'wateringStatus': wateringStatus,
      'soilCondition': soilCondition,
      'temperature': temperature,
      'humidity': humidity,
      'airCirculation': airCirculation,
      'stressFactors': stressFactors,
    };
  }
}