import 'package:flutter/material.dart';
import '../../data/models/sponsorship_tier_comparison.dart';

/// Detailed tier card widget showing all features
/// More comprehensive than the grid card, used in list view
class TierDetailCardWidget extends StatelessWidget {
  final SponsorshipTierComparison tier;
  final bool isSelected;
  final VoidCallback onTap;

  const TierDetailCardWidget({
    super.key,
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isXLTier = tier.tierName == 'XL';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isXLTier
              ? const Color(0xFF10B981)
              : isSelected
                  ? const Color(0xFFD1FAE5)
                  : Colors.white,
          border: Border.all(
            color: isXLTier || isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (tier.isRecommended)
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isXLTier
                    ? const Color(0xFF059669)
                    : isSelected
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Tier Name Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isXLTier
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tier.tierName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isXLTier ? Colors.white : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Recommended/Popular Badge
                  if (tier.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ÖNERİLEN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (tier.isPopular && !tier.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'POPÜLER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Selection Indicator
                  if (isSelected)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isXLTier ? Colors.white : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: isXLTier ? const Color(0xFF10B981) : Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),

            // Price Section
            Container(
              padding: const EdgeInsets.all(16),
              color: isXLTier ? const Color(0xFF10B981) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tier.monthlyPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: isXLTier ? Colors.white : const Color(0xFF10B981),
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${tier.currency}/ay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isXLTier ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Features Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Access
                  _buildFeatureHighlight(
                    '%${tier.sponsorshipFeatures.dataAccessPercentage} Veri Erişimi',
                    Icons.pie_chart,
                    isXLTier,
                  ),
                  const SizedBox(height: 16),

                  // Logo Visibility
                  _buildFeatureRow(
                    'Logo Görünürlüğü',
                    '${tier.sponsorshipFeatures.logoVisibility.visibleScreens.length} ekran',
                    Icons.visibility,
                    isXLTier,
                  ),

                  // Messaging
                  _buildFeatureCheck(
                    'Çiftçilerle Mesajlaşma',
                    tier.sponsorshipFeatures.communication.messagingEnabled,
                    isXLTier,
                  ),

                  // Smart Links
                  if (tier.sponsorshipFeatures.smartLinks.enabled)
                    _buildFeatureRow(
                      'Akıllı Linkler',
                      '${tier.sponsorshipFeatures.smartLinks.quota} adet',
                      Icons.link,
                      isXLTier,
                    )
                  else
                    _buildFeatureCheck(
                      'Akıllı Linkler',
                      false,
                      isXLTier,
                    ),

                  // Farmer Identity
                  _buildFeatureRow(
                    'Çiftçi Kimliği',
                    tier.sponsorshipFeatures.dataAccess.farmerNameContact
                        ? 'Görünür'
                        : 'Anonim',
                    Icons.person,
                    isXLTier,
                  ),

                  // Full Analysis
                  _buildFeatureCheck(
                    'Detaylı Analiz',
                    tier.sponsorshipFeatures.dataAccess.fullAnalysisDetails,
                    isXLTier,
                  ),

                  // Support
                  _buildFeatureRow(
                    'Destek',
                    tier.sponsorshipFeatures.support.prioritySupport
                        ? 'Öncelikli (${tier.sponsorshipFeatures.support.responseTimeHours}s)'
                        : 'Standart (${tier.sponsorshipFeatures.support.responseTimeHours}s)',
                    Icons.support_agent,
                    isXLTier,
                  ),

                  const Divider(height: 24),

                  // Request Limits
                  _buildLimitRow(
                    'Günlük İstek',
                    tier.dailyRequestLimit,
                    isXLTier,
                  ),
                  _buildLimitRow(
                    'Aylık İstek',
                    tier.monthlyRequestLimit,
                    isXLTier,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlight(String text, IconData icon, bool isXLTier) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isXLTier
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isXLTier ? Colors.white : const Color(0xFF10B981),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isXLTier ? Colors.white : const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value, IconData icon, bool isXLTier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isXLTier
                ? Colors.white.withOpacity(0.9)
                : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isXLTier ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isXLTier ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCheck(String label, bool enabled, bool isXLTier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: enabled
                ? (isXLTier ? Colors.white : const Color(0xFF10B981))
                : (isXLTier
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFFEF4444)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isXLTier ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String label, int value, bool isXLTier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isXLTier
                  ? Colors.white.withOpacity(0.9)
                  : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isXLTier ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
