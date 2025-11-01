/// Dealer code model for transferred sponsorship codes
///
/// This model represents codes that have been transferred to a dealer
/// from a sponsor via dealer invitation system.
///
/// Key differences from SponsorshipCode:
/// - No sponsorId (belongs to dealer now)
/// - No sponsorshipPurchaseId (not purchased, transferred)
/// - Has subscriptionTier string (M, L, XL) instead of subscriptionTierId
/// - Has transferredAt timestamp
class DealerCode {
  final int id;
  final String code;
  final bool isUsed;
  final bool isActive;
  final DateTime expiryDate;
  final DateTime createdDate;
  final DateTime transferredAt;
  final String subscriptionTier; // "S", "M", "L", "XL"

  DealerCode({
    required this.id,
    required this.code,
    required this.isUsed,
    required this.isActive,
    required this.expiryDate,
    required this.createdDate,
    required this.transferredAt,
    required this.subscriptionTier,
  });

  /// Convert tier code to numeric ID for compatibility with existing CodePackage logic
  int get subscriptionTierId {
    switch (subscriptionTier.toUpperCase()) {
      case 'S':
        return 2;
      case 'M':
        return 3;
      case 'L':
        return 4;
      case 'XL':
        return 5;
      default:
        return 1; // Trial
    }
  }

  /// Get tier display name
  String get tierDisplayName {
    switch (subscriptionTier.toUpperCase()) {
      case 'S':
        return 'Small';
      case 'M':
        return 'Medium';
      case 'L':
        return 'Large';
      case 'XL':
        return 'Extra Large';
      default:
        return 'Trial';
    }
  }

  factory DealerCode.fromJson(Map<String, dynamic> json) {
    return DealerCode(
      id: json['id'] as int,
      code: json['code'] as String,
      isUsed: json['isUsed'] as bool,
      isActive: json['isActive'] as bool,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      createdDate: DateTime.parse(json['createdDate'] as String),
      transferredAt: DateTime.parse(json['transferredAt'] as String),
      subscriptionTier: json['subscriptionTier'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'isUsed': isUsed,
      'isActive': isActive,
      'expiryDate': expiryDate.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'transferredAt': transferredAt.toIso8601String(),
      'subscriptionTier': subscriptionTier,
    };
  }

  @override
  String toString() {
    return 'DealerCode(id: $id, code: $code, tier: $subscriptionTier, '
        'isUsed: $isUsed, transferredAt: $transferredAt)';
  }
}
