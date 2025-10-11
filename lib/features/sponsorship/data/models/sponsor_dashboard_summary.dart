/// Sponsor Dashboard Summary Data Models
/// Based on API endpoint: /api/v1/sponsorship/dashboard-summary

class SponsorDashboardSummary {
  final int totalCodesCount;
  final int sentCodesCount;
  final double sentCodesPercentage;
  final int totalAnalysesCount;
  final int purchasesCount;
  final double totalSpent;
  final String currency;
  final List<ActivePackageSummary> activePackages;
  final OverallStatistics overallStats;

  SponsorDashboardSummary({
    required this.totalCodesCount,
    required this.sentCodesCount,
    required this.sentCodesPercentage,
    required this.totalAnalysesCount,
    required this.purchasesCount,
    required this.totalSpent,
    required this.currency,
    required this.activePackages,
    required this.overallStats,
  });

  factory SponsorDashboardSummary.fromJson(Map<String, dynamic> json) {
    return SponsorDashboardSummary(
      totalCodesCount: json['totalCodesCount'] ?? 0,
      sentCodesCount: json['sentCodesCount'] ?? 0,
      sentCodesPercentage: (json['sentCodesPercentage'] ?? 0).toDouble(),
      totalAnalysesCount: json['totalAnalysesCount'] ?? 0,
      purchasesCount: json['purchasesCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'TRY',
      activePackages: (json['activePackages'] as List<dynamic>?)
              ?.map((p) => ActivePackageSummary.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      overallStats: json['overallStats'] != null
          ? OverallStatistics.fromJson(json['overallStats'] as Map<String, dynamic>)
          : OverallStatistics.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCodesCount': totalCodesCount,
      'sentCodesCount': sentCodesCount,
      'sentCodesPercentage': sentCodesPercentage,
      'totalAnalysesCount': totalAnalysesCount,
      'purchasesCount': purchasesCount,
      'totalSpent': totalSpent,
      'currency': currency,
      'activePackages': activePackages.map((p) => p.toJson()).toList(),
      'overallStats': overallStats.toJson(),
    };
  }

  /// Create empty summary for initial state
  factory SponsorDashboardSummary.empty() {
    return SponsorDashboardSummary(
      totalCodesCount: 0,
      sentCodesCount: 0,
      sentCodesPercentage: 0,
      totalAnalysesCount: 0,
      purchasesCount: 0,
      totalSpent: 0,
      currency: 'TRY',
      activePackages: [],
      overallStats: OverallStatistics.empty(),
    );
  }
}

class ActivePackageSummary {
  final String tierName;
  final String tierDisplayName;
  final int totalCodes;
  final int sentCodes;
  final int unsentCodes;
  final int usedCodes;
  final int unusedSentCodes;
  final int remainingCodes;
  final double usagePercentage;
  final double distributionPercentage;
  final int uniqueFarmers;
  final int analysesCount;

  ActivePackageSummary({
    required this.tierName,
    required this.tierDisplayName,
    required this.totalCodes,
    required this.sentCodes,
    required this.unsentCodes,
    required this.usedCodes,
    required this.unusedSentCodes,
    required this.remainingCodes,
    required this.usagePercentage,
    required this.distributionPercentage,
    required this.uniqueFarmers,
    required this.analysesCount,
  });

  factory ActivePackageSummary.fromJson(Map<String, dynamic> json) {
    return ActivePackageSummary(
      tierName: json['tierName'] ?? '',
      tierDisplayName: json['tierDisplayName'] ?? '',
      totalCodes: json['totalCodes'] ?? 0,
      sentCodes: json['sentCodes'] ?? 0,
      unsentCodes: json['unsentCodes'] ?? 0,
      usedCodes: json['usedCodes'] ?? 0,
      unusedSentCodes: json['unusedSentCodes'] ?? 0,
      remainingCodes: json['remainingCodes'] ?? 0,
      usagePercentage: (json['usagePercentage'] ?? 0).toDouble(),
      distributionPercentage: (json['distributionPercentage'] ?? 0).toDouble(),
      uniqueFarmers: json['uniqueFarmers'] ?? 0,
      analysesCount: json['analysesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tierName': tierName,
      'tierDisplayName': tierDisplayName,
      'totalCodes': totalCodes,
      'sentCodes': sentCodes,
      'unsentCodes': unsentCodes,
      'usedCodes': usedCodes,
      'unusedSentCodes': unusedSentCodes,
      'remainingCodes': remainingCodes,
      'usagePercentage': usagePercentage,
      'distributionPercentage': distributionPercentage,
      'uniqueFarmers': uniqueFarmers,
      'analysesCount': analysesCount,
    };
  }

  /// Get color based on tier name
  int getTierColor() {
    switch (tierName.toUpperCase()) {
      case 'S':
        return 0xFF10B981; // Green
      case 'M':
        return 0xFF10B981; // Green
      case 'L':
        return 0xFF047857; // Dark Green
      case 'XL':
        return 0xFF065F46; // Darker Green
      default:
        return 0xFF6B7280; // Gray
    }
  }
}

class OverallStatistics {
  final int smsDistributions;
  final int whatsAppDistributions;
  final double overallRedemptionRate;
  final double averageRedemptionTime;
  final int totalUniqueFarmers;
  final DateTime? lastPurchaseDate;
  final DateTime? lastDistributionDate;

  OverallStatistics({
    required this.smsDistributions,
    required this.whatsAppDistributions,
    required this.overallRedemptionRate,
    required this.averageRedemptionTime,
    required this.totalUniqueFarmers,
    this.lastPurchaseDate,
    this.lastDistributionDate,
  });

  factory OverallStatistics.fromJson(Map<String, dynamic> json) {
    return OverallStatistics(
      smsDistributions: json['smsDistributions'] ?? 0,
      whatsAppDistributions: json['whatsAppDistributions'] ?? 0,
      overallRedemptionRate: (json['overallRedemptionRate'] ?? 0).toDouble(),
      averageRedemptionTime: (json['averageRedemptionTime'] ?? 0).toDouble(),
      totalUniqueFarmers: json['totalUniqueFarmers'] ?? 0,
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.tryParse(json['lastPurchaseDate'] as String)
          : null,
      lastDistributionDate: json['lastDistributionDate'] != null
          ? DateTime.tryParse(json['lastDistributionDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'smsDistributions': smsDistributions,
      'whatsAppDistributions': whatsAppDistributions,
      'overallRedemptionRate': overallRedemptionRate,
      'averageRedemptionTime': averageRedemptionTime,
      'totalUniqueFarmers': totalUniqueFarmers,
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
      'lastDistributionDate': lastDistributionDate?.toIso8601String(),
    };
  }

  factory OverallStatistics.empty() {
    return OverallStatistics(
      smsDistributions: 0,
      whatsAppDistributions: 0,
      overallRedemptionRate: 0,
      averageRedemptionTime: 0,
      totalUniqueFarmers: 0,
    );
  }
}
