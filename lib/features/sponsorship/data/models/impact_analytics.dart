/// Data model for impact analytics endpoint response
class ImpactAnalytics {
  final int totalFarmersReached;
  final int activeFarmersLast30Days;
  final double farmerRetentionRate;
  final double averageFarmerLifetimeDays;
  final int totalCropsAnalyzed;
  final int uniqueCropTypes;
  final int diseasesDetected;
  final int criticalIssuesResolved;
  final int citiesReached;
  final int districtsReached;
  final List<TopCity> topCities;
  final SeverityDistribution severityDistribution;
  final List<TopCrop> topCrops;
  final List<TopDisease> topDiseases;
  final DateTime dataStartDate;
  final DateTime dataEndDate;

  ImpactAnalytics({
    required this.totalFarmersReached,
    required this.activeFarmersLast30Days,
    required this.farmerRetentionRate,
    required this.averageFarmerLifetimeDays,
    required this.totalCropsAnalyzed,
    required this.uniqueCropTypes,
    required this.diseasesDetected,
    required this.criticalIssuesResolved,
    required this.citiesReached,
    required this.districtsReached,
    required this.topCities,
    required this.severityDistribution,
    required this.topCrops,
    required this.topDiseases,
    required this.dataStartDate,
    required this.dataEndDate,
  });

  factory ImpactAnalytics.fromJson(Map<String, dynamic> json) {
    return ImpactAnalytics(
      totalFarmersReached: json['totalFarmersReached'] as int,
      activeFarmersLast30Days: json['activeFarmersLast30Days'] as int,
      farmerRetentionRate: (json['farmerRetentionRate'] as num).toDouble(),
      averageFarmerLifetimeDays: (json['averageFarmerLifetimeDays'] as num).toDouble(),
      totalCropsAnalyzed: json['totalCropsAnalyzed'] as int,
      uniqueCropTypes: json['uniqueCropTypes'] as int,
      diseasesDetected: json['diseasesDetected'] as int,
      criticalIssuesResolved: json['criticalIssuesResolved'] as int,
      citiesReached: json['citiesReached'] as int,
      districtsReached: json['districtsReached'] as int,
      topCities: (json['topCities'] as List)
          .map((item) => TopCity.fromJson(item))
          .toList(),
      severityDistribution: SeverityDistribution.fromJson(json['severityDistribution']),
      topCrops: (json['topCrops'] as List)
          .map((item) => TopCrop.fromJson(item))
          .toList(),
      topDiseases: (json['topDiseases'] as List)
          .map((item) => TopDisease.fromJson(item))
          .toList(),
      dataStartDate: DateTime.parse(json['dataStartDate'] as String),
      dataEndDate: DateTime.parse(json['dataEndDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFarmersReached': totalFarmersReached,
      'activeFarmersLast30Days': activeFarmersLast30Days,
      'farmerRetentionRate': farmerRetentionRate,
      'averageFarmerLifetimeDays': averageFarmerLifetimeDays,
      'totalCropsAnalyzed': totalCropsAnalyzed,
      'uniqueCropTypes': uniqueCropTypes,
      'diseasesDetected': diseasesDetected,
      'criticalIssuesResolved': criticalIssuesResolved,
      'citiesReached': citiesReached,
      'districtsReached': districtsReached,
      'topCities': topCities.map((e) => e.toJson()).toList(),
      'severityDistribution': severityDistribution.toJson(),
      'topCrops': topCrops.map((e) => e.toJson()).toList(),
      'topDiseases': topDiseases.map((e) => e.toJson()).toList(),
      'dataStartDate': dataStartDate.toIso8601String(),
      'dataEndDate': dataEndDate.toIso8601String(),
    };
  }

  /// Get formatted date range
  String get formattedDateRange {
    final months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];

    final startDay = dataStartDate.day;
    final startMonth = months[dataStartDate.month - 1];
    final endDay = dataEndDate.day;
    final endMonth = months[dataEndDate.month - 1];
    final year = dataEndDate.year;

    return '$startDay $startMonth - $endDay $endMonth $year';
  }
}

/// Top city data with analysis statistics
class TopCity {
  final String cityName;
  final int farmerCount;
  final int analysisCount;
  final double percentage;
  final String mostCommonCrop;
  final String mostCommonDisease;

  TopCity({
    required this.cityName,
    required this.farmerCount,
    required this.analysisCount,
    required this.percentage,
    required this.mostCommonCrop,
    required this.mostCommonDisease,
  });

  factory TopCity.fromJson(Map<String, dynamic> json) {
    return TopCity(
      cityName: json['cityName'] as String,
      farmerCount: json['farmerCount'] as int,
      analysisCount: json['analysisCount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      mostCommonCrop: json['mostCommonCrop'] as String,
      mostCommonDisease: json['mostCommonDisease'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'farmerCount': farmerCount,
      'analysisCount': analysisCount,
      'percentage': percentage,
      'mostCommonCrop': mostCommonCrop,
      'mostCommonDisease': mostCommonDisease,
    };
  }
}

/// Severity distribution statistics
class SeverityDistribution {
  final int lowSeverityCount;
  final int moderateSeverityCount;
  final int highSeverityCount;
  final int criticalSeverityCount;
  final double lowPercentage;
  final double moderatePercentage;
  final double highPercentage;
  final double criticalPercentage;

  SeverityDistribution({
    required this.lowSeverityCount,
    required this.moderateSeverityCount,
    required this.highSeverityCount,
    required this.criticalSeverityCount,
    required this.lowPercentage,
    required this.moderatePercentage,
    required this.highPercentage,
    required this.criticalPercentage,
  });

  factory SeverityDistribution.fromJson(Map<String, dynamic> json) {
    return SeverityDistribution(
      lowSeverityCount: json['lowSeverityCount'] as int,
      moderateSeverityCount: json['moderateSeverityCount'] as int,
      highSeverityCount: json['highSeverityCount'] as int,
      criticalSeverityCount: json['criticalSeverityCount'] as int,
      lowPercentage: (json['lowPercentage'] as num).toDouble(),
      moderatePercentage: (json['moderatePercentage'] as num).toDouble(),
      highPercentage: (json['highPercentage'] as num).toDouble(),
      criticalPercentage: (json['criticalPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lowSeverityCount': lowSeverityCount,
      'moderateSeverityCount': moderateSeverityCount,
      'highSeverityCount': highSeverityCount,
      'criticalSeverityCount': criticalSeverityCount,
      'lowPercentage': lowPercentage,
      'moderatePercentage': moderatePercentage,
      'highPercentage': highPercentage,
      'criticalPercentage': criticalPercentage,
    };
  }

  /// Get total issue count
  int get totalCount {
    return lowSeverityCount + moderateSeverityCount + highSeverityCount + criticalSeverityCount;
  }
}

/// Top crop data with statistics
class TopCrop {
  final String cropType;
  final int analysisCount;
  final double percentage;
  final int uniqueFarmers;

  TopCrop({
    required this.cropType,
    required this.analysisCount,
    required this.percentage,
    required this.uniqueFarmers,
  });

  factory TopCrop.fromJson(Map<String, dynamic> json) {
    return TopCrop(
      cropType: json['cropType'] as String,
      analysisCount: json['analysisCount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      uniqueFarmers: json['uniqueFarmers'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cropType': cropType,
      'analysisCount': analysisCount,
      'percentage': percentage,
      'uniqueFarmers': uniqueFarmers,
    };
  }
}

/// Top disease data with statistics
class TopDisease {
  final String diseaseName;
  final String category;
  final int occurrenceCount;
  final double percentage;
  final List<String> affectedCrops;
  final String mostCommonSeverity;
  final List<String> topCities;

  TopDisease({
    required this.diseaseName,
    required this.category,
    required this.occurrenceCount,
    required this.percentage,
    required this.affectedCrops,
    required this.mostCommonSeverity,
    required this.topCities,
  });

  factory TopDisease.fromJson(Map<String, dynamic> json) {
    return TopDisease(
      diseaseName: json['diseaseName'] as String,
      category: json['category'] as String,
      occurrenceCount: json['occurrenceCount'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      affectedCrops: List<String>.from(json['affectedCrops'] as List),
      mostCommonSeverity: json['mostCommonSeverity'] as String,
      topCities: List<String>.from(json['topCities'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diseaseName': diseaseName,
      'category': category,
      'occurrenceCount': occurrenceCount,
      'percentage': percentage,
      'affectedCrops': affectedCrops,
      'mostCommonSeverity': mostCommonSeverity,
      'topCities': topCities,
    };
  }
}
