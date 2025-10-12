import 'package:flutter/material.dart';
import '../../data/models/sponsorship_tier_comparison.dart';

/// Tier card widget matching sponsor_packages.png design
/// Shows tier name, price, data access percentage, and key features
class TierCardWidget extends StatelessWidget {
  final SponsorshipTierComparison tier;
  final bool isSelected;
  final VoidCallback onTap;

  const TierCardWidget({
    super.key,
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // XL tier gets premium dark green background
    final isXLTier = tier.tierName == 'XL';

    // Selected tier gets light green background (unless XL)
    final backgroundColor = isXLTier
        ? const Color(0xFF10B981) // Dark green for XL
        : isSelected
            ? const Color(0xFFD1FAE5) // Light green for selected
            : Colors.white; // White for unselected

    // Border color
    final borderColor = isXLTier
        ? const Color(0xFF10B981) // Dark green border for XL
        : isSelected
            ? const Color(0xFF10B981) // Green border for selected
            : const Color(0xFFE5E7EB); // Gray border for unselected

    // Text colors
    final primaryTextColor = isXLTier ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isXLTier
        ? Colors.white.withOpacity(0.9)
        : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Main content - SingleChildScrollView to prevent overflow
            Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tier name (large, centered)
                    Center(
                      child: Text(
                        tier.tierName,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Price
                    Center(
                      child: Text(
                        '${tier.monthlyPrice.toStringAsFixed(0)} ${tier.currency}/ay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Data access percentage
                    Text(
                      '%${tier.sponsorshipFeatures.dataAccessPercentage} görünürlük',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Feature list
                    ..._buildFeatureList(secondaryTextColor),
                  ],
                ),
              ),
            ),

            // Check mark for selected tier (except XL which is always visible)
            if (isSelected && !isXLTier)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList(Color textColor) {
    final features = <String>[];

    // Always show: Çiftçi analiz sonuçlarının kısmi görünürlüğü
    features.add('• Çiftçi analiz sonuçlarının kısmi görünürlüğü');

    // Always show: Ürün ve hastalık analizleri
    features.add('• Ürün ve hastalık analizleri');

    // XL tier: Show extra features
    if (tier.tierName == 'XL') {
      features.add('• Ek fayda');
      features.add('• Çiftçilerle mesajlaşma');
    }

    return features
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
        )
        .toList();
  }
}
