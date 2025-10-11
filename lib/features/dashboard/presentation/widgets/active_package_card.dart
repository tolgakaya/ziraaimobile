import 'package:flutter/material.dart';
import '../../../sponsorship/data/models/sponsor_dashboard_summary.dart';

/// Active Package card widget
/// Displays tier information, usage stats, and progress bar
class ActivePackageCard extends StatelessWidget {
  final ActivePackageSummary package;

  const ActivePackageCard({
    super.key,
    required this.package,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tier badge and total codes
          Row(
            children: [
              // Tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(package.getTierColor()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${package.tierName} Paketi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              // Total codes
              Text(
                '${package.totalCodes} Kod',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Usage info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${package.sentCodes} aktif / ${package.unsentCodes} kullanılmadı',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: package.totalCodes > 0
                  ? package.sentCodes / package.totalCodes
                  : 0,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(package.getTierColor()),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // Remaining codes
          Text(
            'Kalan Kod: ${package.remainingCodes}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
