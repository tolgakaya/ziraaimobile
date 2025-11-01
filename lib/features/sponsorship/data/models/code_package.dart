import 'sponsorship_code.dart';
import 'unified_code.dart';

class CodePackage {
  final int purchaseId; // Use 0 for dealer codes (no purchase ID)
  final int tierId;
  final String tierName;
  final List<SponsorshipCode> codes;
  final DateTime purchaseDate;
  final int? packageTotalCodes; // Total codes in package from dashboard (nullable for backward compatibility)
  final bool isDealerPackage; // True if this package contains dealer transferred codes

  CodePackage({
    required this.purchaseId,
    required this.tierId,
    required this.tierName,
    required this.codes,
    required this.purchaseDate,
    this.packageTotalCodes,
    this.isDealerPackage = false,
  });

  int get unusedCount => codes.where((code) => !code.isUsed).length;

  // Use packageTotalCodes from dashboard if available, otherwise fallback to codes.length
  int get totalCount => packageTotalCodes ?? codes.length;

  String get displayName {
    // Tier name mapping
    final tierNameMap = {
      1: 'Trial',
      2: 'S',
      3: 'M',
      4: 'L',
      5: 'XL',
    };

    final name = tierNameMap[tierId] ?? 'Bilinmeyen';

    // Different display for dealer codes
    if (isDealerPackage) {
      return 'Bayi Kodları - $name (${codes.length} Kod)';
    }

    // Show unsent count (codes.length) vs total package codes for sponsor
    return 'Paket $name (${codes.length} / $totalCount Kod)';
  }

  /// Group codes by purchaseId with optional dashboard total codes mapping
  static List<CodePackage> groupByPurchase(
    List<SponsorshipCode> codes, {
    Map<int, int>? packageTotalCodesMap,
  }) {
    if (codes.isEmpty) return [];

    // Group by purchaseId
    final Map<int, List<SponsorshipCode>> grouped = {};

    for (final code in codes) {
      grouped.putIfAbsent(code.sponsorshipPurchaseId, () => []).add(code);
    }

    // Create CodePackage instances
    return grouped.entries.map((entry) {
      final purchaseId = entry.key;
      final packageCodes = entry.value;

      // All codes in same package have same tier and purchase date
      final firstCode = packageCodes.first;

      return CodePackage(
        purchaseId: purchaseId,
        tierId: firstCode.subscriptionTierId,
        tierName: '', // Will be set by displayName getter
        codes: packageCodes,
        purchaseDate: firstCode.createdDate,
        packageTotalCodes: packageTotalCodesMap?[purchaseId],
        isDealerPackage: false,
      );
    }).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Sort by newest first
  }

  /// Group dealer codes by tier (since they don't have purchaseId)
  /// Dealer codes are grouped by tier instead of purchase
  static List<CodePackage> groupDealerCodesByTier(
    List<UnifiedCode> dealerCodes, {
    int? totalCodesCount,
  }) {
    if (dealerCodes.isEmpty) return [];

    // Group by tier ID
    final Map<int, List<SponsorshipCode>> grouped = {};

    for (final unifiedCode in dealerCodes) {
      // Convert UnifiedCode to SponsorshipCode for compatibility
      final sponsorshipCode = SponsorshipCode(
        id: unifiedCode.id,
        code: unifiedCode.code,
        sponsorId: 0, // Not applicable for dealer codes
        subscriptionTierId: unifiedCode.subscriptionTierId,
        sponsorshipPurchaseId: 0, // Dealer codes don't have purchase ID
        isUsed: unifiedCode.isUsed,
        createdDate: unifiedCode.createdDate,
        expiryDate: unifiedCode.expiryDate,
        isActive: unifiedCode.isActive,
        linkClickCount: 0,
        linkDelivered: false,
      );

      grouped.putIfAbsent(unifiedCode.subscriptionTierId, () => []).add(sponsorshipCode);
    }

    // Create CodePackage instances grouped by tier
    return grouped.entries.map((entry) {
      final tierId = entry.key;
      final tierCodes = entry.value;

      // Use earliest transfer date as "purchase" date for sorting
      final firstCode = tierCodes.first;

      return CodePackage(
        purchaseId: 0, // No purchase ID for dealer codes
        tierId: tierId,
        tierName: '', // Will be set by displayName getter
        codes: tierCodes,
        purchaseDate: firstCode.createdDate,
        packageTotalCodes: totalCodesCount,
        isDealerPackage: true,
      );
    }).toList()
      ..sort((a, b) => b.tierId.compareTo(a.tierId)); // Sort by tier (highest first)
  }
}
