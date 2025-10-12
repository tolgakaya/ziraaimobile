import 'sponsorship_features.dart';

/// Sponsorship tier comparison model for package purchase selection
/// Maps to backend SponsorshipTierComparisonDto
class SponsorshipTierComparison {
  final int id;
  final String tierName; // "S", "M", "L", "XL"
  final String displayName;
  final String? description;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final int minPurchaseQuantity;
  final int maxPurchaseQuantity;
  final int recommendedQuantity;
  final int dailyRequestLimit;
  final int monthlyRequestLimit;
  final SponsorshipFeatures sponsorshipFeatures;
  final bool isPopular;
  final bool isRecommended;
  final int displayOrder;

  SponsorshipTierComparison({
    required this.id,
    required this.tierName,
    required this.displayName,
    this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
    required this.minPurchaseQuantity,
    required this.maxPurchaseQuantity,
    required this.recommendedQuantity,
    required this.dailyRequestLimit,
    required this.monthlyRequestLimit,
    required this.sponsorshipFeatures,
    required this.isPopular,
    required this.isRecommended,
    required this.displayOrder,
  });

  factory SponsorshipTierComparison.fromJson(Map<String, dynamic> json) {
    return SponsorshipTierComparison(
      id: json['id'] as int,
      tierName: json['tierName'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num).toDouble(),
      currency: json['currency'] as String,
      minPurchaseQuantity: json['minPurchaseQuantity'] as int,
      maxPurchaseQuantity: json['maxPurchaseQuantity'] as int,
      recommendedQuantity: json['recommendedQuantity'] as int,
      dailyRequestLimit: json['dailyRequestLimit'] as int,
      monthlyRequestLimit: json['monthlyRequestLimit'] as int,
      sponsorshipFeatures: SponsorshipFeatures.fromJson(
        json['sponsorshipFeatures'] as Map<String, dynamic>,
      ),
      isPopular: json['isPopular'] as bool,
      isRecommended: json['isRecommended'] as bool,
      displayOrder: json['displayOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tierName': tierName,
      'displayName': displayName,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'currency': currency,
      'minPurchaseQuantity': minPurchaseQuantity,
      'maxPurchaseQuantity': maxPurchaseQuantity,
      'recommendedQuantity': recommendedQuantity,
      'dailyRequestLimit': dailyRequestLimit,
      'monthlyRequestLimit': monthlyRequestLimit,
      'sponsorshipFeatures': sponsorshipFeatures.toJson(),
      'isPopular': isPopular,
      'isRecommended': isRecommended,
      'displayOrder': displayOrder,
    };
  }
}
