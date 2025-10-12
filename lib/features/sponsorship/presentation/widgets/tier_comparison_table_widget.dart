import 'package:flutter/material.dart';
import '../../data/models/sponsorship_tier_comparison.dart';

/// Comprehensive tier comparison table widget
/// Shows all tier features in a scrollable comparison table
class TierComparisonTableWidget extends StatelessWidget {
  final List<SponsorshipTierComparison> tiers;
  final SponsorshipTierComparison? selectedTier;
  final Function(SponsorshipTierComparison) onTierSelected;

  const TierComparisonTableWidget({
    super.key,
    required this.tiers,
    required this.selectedTier,
    required this.onTierSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(const Color(0xFFF3F4F6)),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        columns: [
          const DataColumn(
            label: Text(
              'Özellikler',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
          ),
          ...tiers.map((tier) => DataColumn(
                label: GestureDetector(
                  onTap: () => onTierSelected(tier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedTier?.id == tier.id
                          ? const Color(0xFF10B981)
                          : tier.tierName == 'XL'
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          tier.tierName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: selectedTier?.id == tier.id
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        if (tier.isRecommended)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'ÖNERİLEN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
        rows: [
          // Price/month
          _buildDataRow(
            'Aylık Fiyat',
            tiers.map((t) => '${t.monthlyPrice.toStringAsFixed(0)} ${t.currency}').toList(),
            isHighlight: true,
          ),

          // Data Access %
          _buildDataRow(
            'Veri Erişimi',
            tiers.map((t) => '%${t.sponsorshipFeatures.dataAccessPercentage}').toList(),
          ),

          // Logo Screens
          _buildDataRow(
            'Logo Görünürlüğü',
            tiers.map((t) => '${t.sponsorshipFeatures.logoVisibility.visibleScreens.length} ekran').toList(),
          ),

          // Messaging
          _buildCheckRow(
            'Çiftçilerle Mesajlaşma',
            tiers.map((t) => t.sponsorshipFeatures.communication.messagingEnabled).toList(),
          ),

          // Smart Links
          _buildDataRow(
            'Akıllı Linkler',
            tiers.map((t) {
              if (t.sponsorshipFeatures.smartLinks.enabled) {
                return '✅ (${t.sponsorshipFeatures.smartLinks.quota} adet)';
              }
              return '❌';
            }).toList(),
          ),

          // Farmer Identity
          _buildDataRow(
            'Çiftçi Kimliği',
            tiers.map((t) {
              return t.sponsorshipFeatures.dataAccess.farmerNameContact
                  ? 'Görünür'
                  : 'Anonim';
            }).toList(),
          ),

          // Full Analysis
          _buildCheckRow(
            'Detaylı Analiz',
            tiers.map((t) => t.sponsorshipFeatures.dataAccess.fullAnalysisDetails).toList(),
          ),

          // Analysis Images
          _buildCheckRow(
            'Analiz Görselleri',
            tiers.map((t) => t.sponsorshipFeatures.dataAccess.analysisImages).toList(),
          ),

          // AI Recommendations
          _buildCheckRow(
            'AI Önerileri',
            tiers.map((t) => t.sponsorshipFeatures.dataAccess.aiRecommendations).toList(),
          ),

          // Crop Types
          _buildCheckRow(
            'Ürün Türleri',
            tiers.map((t) => t.sponsorshipFeatures.dataAccess.cropTypes).toList(),
          ),

          // Disease Categories
          _buildCheckRow(
            'Hastalık Kategorileri',
            tiers.map((t) => t.sponsorshipFeatures.dataAccess.diseaseCategories).toList(),
          ),

          // Location Data
          _buildDataRow(
            'Konum Bilgisi',
            tiers.map((t) {
              if (t.sponsorshipFeatures.dataAccess.locationCoordinates) {
                return 'Koordinatlar';
              } else if (t.sponsorshipFeatures.dataAccess.locationDistrict) {
                return 'İlçe';
              } else if (t.sponsorshipFeatures.dataAccess.locationCity) {
                return 'İl';
              }
              return '❌';
            }).toList(),
          ),

          // Support
          _buildDataRow(
            'Destek',
            tiers.map((t) {
              if (t.sponsorshipFeatures.support.prioritySupport) {
                return 'Öncelikli (${t.sponsorshipFeatures.support.responseTimeHours}s)';
              }
              return 'Standart (${t.sponsorshipFeatures.support.responseTimeHours}s)';
            }).toList(),
          ),

          // Daily Request Limit
          _buildDataRow(
            'Günlük İstek Limiti',
            tiers.map((t) => '${t.dailyRequestLimit}').toList(),
          ),

          // Monthly Request Limit
          _buildDataRow(
            'Aylık İstek Limiti',
            tiers.map((t) => '${t.monthlyRequestLimit}').toList(),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String label, List<String> values, {bool isHighlight = false}) {
    return DataRow(
      color: isHighlight
          ? MaterialStateProperty.all(const Color(0xFFF9FAFB))
          : null,
      cells: [
        DataCell(
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        ...values.map((value) => DataCell(
              Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                    color: isHighlight
                        ? const Color(0xFF10B981)
                        : const Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )),
      ],
    );
  }

  DataRow _buildCheckRow(String label, List<bool> values) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ),
        ...values.map((enabled) => DataCell(
              Center(
                child: Icon(
                  enabled ? Icons.check_circle : Icons.cancel,
                  color: enabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
            )),
      ],
    );
  }
}
