/// Data model for sponsor statistics endpoint response
class SponsorStatistics {
  final double totalSpent;
  final int totalCodesPurchased;
  final int totalCodesUsed;
  final double usageRate;
  final int unusedCodes;
  final Map<String, int> usageByTier;

  SponsorStatistics({
    required this.totalSpent,
    required this.totalCodesPurchased,
    required this.totalCodesUsed,
    required this.usageRate,
    required this.unusedCodes,
    required this.usageByTier,
  });

  factory SponsorStatistics.fromJson(Map<String, dynamic> json) {
    return SponsorStatistics(
      totalSpent: (json['totalSpent'] as num).toDouble(),
      totalCodesPurchased: json['totalCodesPurchased'] as int,
      totalCodesUsed: json['totalCodesUsed'] as int,
      usageRate: (json['usageRate'] as num).toDouble(),
      unusedCodes: json['unusedCodes'] as int,
      usageByTier: Map<String, int>.from(
        (json['usageByTier'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as int),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSpent': totalSpent,
      'totalCodesPurchased': totalCodesPurchased,
      'totalCodesUsed': totalCodesUsed,
      'usageRate': usageRate,
      'unusedCodes': unusedCodes,
      'usageByTier': usageByTier,
    };
  }

  /// Get formatted total spent with currency
  String get formattedTotalSpent {
    return '${totalSpent.toStringAsFixed(2)} TRY';
  }

  /// Get formatted usage rate as percentage
  String get formattedUsageRate {
    return '${usageRate.toStringAsFixed(1)}%';
  }
}
