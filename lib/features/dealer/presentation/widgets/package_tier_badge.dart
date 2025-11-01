import 'package:flutter/material.dart';

/// Package tier badge widget
///
/// Displays a visual badge for sponsorship package tiers (S, M, L, XL)
/// with appropriate colors and labels
class PackageTierBadge extends StatelessWidget {
  final String tier;
  final bool showLabel;
  final double iconSize;

  const PackageTierBadge({
    Key? key,
    required this.tier,
    this.showLabel = true,
    this.iconSize = 16,
  }) : super(key: key);

  /// Get color for tier
  Color get tierColor {
    switch (tier.toUpperCase()) {
      case 'S':
        return Colors.blue;
      case 'M':
        return Colors.green;
      case 'L':
        return Colors.orange;
      case 'XL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get display label for tier
  String get tierLabel {
    switch (tier.toUpperCase()) {
      case 'S':
        return showLabel ? 'Small (1 analiz/gün)' : 'S';
      case 'M':
        return showLabel ? 'Medium (2 analiz/gün)' : 'M';
      case 'L':
        return showLabel ? 'Large (5 analiz/gün)' : 'L';
      case 'XL':
        return showLabel ? 'Extra Large (10 analiz/gün)' : 'XL';
      default:
        return tier;
    }
  }

  /// Get icon for tier
  IconData get tierIcon {
    switch (tier.toUpperCase()) {
      case 'S':
        return Icons.card_giftcard;
      case 'M':
        return Icons.card_giftcard;
      case 'L':
        return Icons.card_giftcard;
      case 'XL':
        return Icons.card_giftcard;
      default:
        return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tierColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tierIcon,
            size: iconSize,
            color: tierColor,
          ),
          const SizedBox(width: 6),
          Text(
            tierLabel,
            style: TextStyle(
              color: tierColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tier badge (icon + tier letter only)
class CompactTierBadge extends StatelessWidget {
  final String tier;

  const CompactTierBadge({
    Key? key,
    required this.tier,
  }) : super(key: key);

  Color get tierColor {
    switch (tier.toUpperCase()) {
      case 'S':
        return Colors.blue;
      case 'M':
        return Colors.green;
      case 'L':
        return Colors.orange;
      case 'XL':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tierColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tier.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
