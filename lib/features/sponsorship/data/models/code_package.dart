import 'sponsorship_code.dart';

class CodePackage {
  final int purchaseId;
  final int tierId;
  final String tierName;
  final List<SponsorshipCode> codes;
  final DateTime purchaseDate;

  CodePackage({
    required this.purchaseId,
    required this.tierId,
    required this.tierName,
    required this.codes,
    required this.purchaseDate,
  });

  int get unusedCount => codes.where((code) => !code.isUsed).length;

  int get totalCount => codes.length;

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
    return 'Paket $name ($unusedCount / $totalCount Kod)';
  }

  /// Group codes by purchaseId
  static List<CodePackage> groupByPurchase(List<SponsorshipCode> codes) {
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
      );
    }).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)); // Sort by newest first
  }
}
