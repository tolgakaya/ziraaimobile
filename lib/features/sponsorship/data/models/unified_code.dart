import 'sponsorship_code.dart';
import '../../../dealer/domain/models/dealer_code.dart';

/// Unified code wrapper for both SponsorshipCode and DealerCode
///
/// This allows CodePackage to work with both sponsor purchased codes
/// and dealer transferred codes seamlessly.
class UnifiedCode {
  final int id;
  final String code;
  final int subscriptionTierId;
  final int? sponsorshipPurchaseId; // Null for dealer codes
  final bool isUsed;
  final DateTime createdDate;
  final DateTime expiryDate;
  final bool isActive;
  final bool isDealerCode; // True if this is a dealer transferred code

  UnifiedCode({
    required this.id,
    required this.code,
    required this.subscriptionTierId,
    this.sponsorshipPurchaseId,
    required this.isUsed,
    required this.createdDate,
    required this.expiryDate,
    required this.isActive,
    this.isDealerCode = false,
  });

  /// Create from SponsorshipCode
  factory UnifiedCode.fromSponsorCode(SponsorshipCode sponsorCode) {
    return UnifiedCode(
      id: sponsorCode.id,
      code: sponsorCode.code,
      subscriptionTierId: sponsorCode.subscriptionTierId,
      sponsorshipPurchaseId: sponsorCode.sponsorshipPurchaseId,
      isUsed: sponsorCode.isUsed,
      createdDate: sponsorCode.createdDate,
      expiryDate: sponsorCode.expiryDate,
      isActive: sponsorCode.isActive,
      isDealerCode: false,
    );
  }

  /// Create from DealerCode
  factory UnifiedCode.fromDealerCode(DealerCode dealerCode) {
    return UnifiedCode(
      id: dealerCode.id,
      code: dealerCode.code,
      subscriptionTierId: dealerCode.subscriptionTierId,
      sponsorshipPurchaseId: null, // Dealer codes don't have purchase ID
      isUsed: dealerCode.isUsed,
      createdDate: dealerCode.createdDate,
      expiryDate: dealerCode.expiryDate,
      isActive: dealerCode.isActive,
      isDealerCode: true,
    );
  }

  @override
  String toString() {
    return 'UnifiedCode(id: $id, code: $code, tier: $subscriptionTierId, '
        'isDealer: $isDealerCode, isUsed: $isUsed)';
  }
}
