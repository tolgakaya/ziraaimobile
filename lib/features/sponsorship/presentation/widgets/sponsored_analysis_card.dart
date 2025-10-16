import 'package:flutter/material.dart';
import '../../data/models/sponsored_analysis_summary.dart';

/// Individual analysis card with tier-based field visibility
/// Follows farmer dashboard card pattern with conditional rendering
class SponsoredAnalysisCard extends StatelessWidget {
  final SponsoredAnalysisSummary analysis;
  final VoidCallback onTap;

  const SponsoredAnalysisCard({
    super.key,
    required this.analysis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and tier badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    analysis.analysisDateFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  _buildTierBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Crop type and health score (always visible)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      analysis.cropType ?? 'Bilinmiyor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (analysis.hasBasicAccess &&
                      analysis.overallHealthScore != null)
                    _buildHealthScoreBadge(context),
                ],
              ),

              // Plant species and variety (30% access - S/M tier)
              if (analysis.hasBasicAccess && analysis.plantSpecies != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${analysis.plantSpecies}${analysis.plantVariety != null ? ' - ${analysis.plantVariety}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],

              // Growth stage (30% access)
              if (analysis.hasBasicAccess && analysis.growthStage != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.spa, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      analysis.growthStage!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],

              // Plant image (30% access)
              if (analysis.hasBasicAccess &&
                  analysis.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    analysis.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_florist,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Primary concern (60% access - L tier)
              if (analysis.hasDetailedAccess &&
                  analysis.primaryConcern != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(analysis.healthSeverity)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getSeverityColor(analysis.healthSeverity),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: _getSeverityColor(analysis.healthSeverity),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          analysis.primaryConcern!,
                          style: TextStyle(
                            color: _getSeverityColor(analysis.healthSeverity),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Sponsor branding (if logo available)
              if (analysis.canViewLogo == true &&
                  analysis.sponsorInfo?.logoUrl != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Sponsorlu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Image.network(
                      analysis.sponsorInfo?.logoUrl ?? '',
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          analysis.sponsorInfo?.companyName ?? 'Sponsor',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build tier badge (S/M: blue, L: orange, XL: purple)
  Widget _buildTierBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTierColor(analysis.tierName ?? 'S').withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTierColor(analysis.tierName ?? 'S'),
          width: 1,
        ),
      ),
      child: Text(
        analysis.tierName ?? 'N/A',
        style: TextStyle(
          color: _getTierColor(analysis.tierName ?? 'S'),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build health score badge with color coding
  Widget _buildHealthScoreBadge(BuildContext context) {
    final score = analysis.overallHealthScore ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getHealthScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 16,
            color: _getHealthScoreColor(score),
          ),
          const SizedBox(width: 4),
          Text(
            analysis.healthScoreText,
            style: TextStyle(
              color: _getHealthScoreColor(score),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get tier color (S/M: blue, L: orange, XL: purple)
  Color _getTierColor(String tierName) {
    if (tierName.contains('S') || tierName.contains('M')) {
      return Colors.blue;
    } else if (tierName == 'L') {
      return Colors.orange;
    } else if (tierName == 'XL') {
      return Colors.purple;
    }
    return Colors.grey;
  }

  /// Get health score color (green: 80+, orange: 60-79, red: 0-59)
  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  /// Get severity color (Healthy: green, Moderate: orange, Critical: red)
  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
