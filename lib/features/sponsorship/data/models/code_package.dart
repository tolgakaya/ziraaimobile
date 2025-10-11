import 'sponsorship_code.dart';

class CodePackage {
  final int purchaseId;
  final int tierId;
  final String tierName;
  final List<SponsorshipCode> codes;
  final DateTime purchaseDate;
  final int? packageTotalCodes; // Total codes in package from dashboard (nullable for backward compatibility)

  CodePackage({
    required this.purchaseId,
    required this.tierId,
    required this.tierName,
    required this.codes,
    required this.purchaseDate,
    this.packageTotalCodes,
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
    // Show unsent count (codes.length) vs total package codes
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
      );
    }).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Sort by newest first
  }
}
