import 'package:flutter/material.dart';
import '../../data/models/sponsored_analysis_summary.dart';
import 'envelope_icon.dart';
import 'unread_badge.dart';

/// Individual analysis card for sponsor with farmer card design pattern
/// Image-first layout with message badge overlay in top-left corner
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Status Badge
            Container(
              height: 200,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: Color(0xFFF3F4F6),
              ),
              child: Stack(
                children: [
                  // Plant Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: _buildPlantImage(analysis.imageUrl),
                  ),
                  // Health Status Badge (bottom-right)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildHealthBadge(context),
                  ),
                  // Message Badge Overlay (top-left corner)
                  if (analysis.hasMessages)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildMessageBadge(),
                    ),
                ],
              ),
            ),

            // Plant Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant name and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          analysis.cropType ?? 'Bilinmeyen Bitki',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        analysis.analysisDateFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Plant species and variety
                  if (analysis.hasBasicAccess && analysis.plantSpecies != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${analysis.plantSpecies}${analysis.plantVariety != null ? ' - ${analysis.plantVariety}' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build compact message badge for image overlay
  Widget _buildMessageBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: analysis.hasUnreadMessages
            ? Colors.blue.withOpacity(0.95)
            : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Envelope icon
          EnvelopeIcon(
            hasMessages: analysis.hasMessages,
            hasUnreadMessages: analysis.hasUnreadMessages,
            hasUnreadFromFarmer: analysis.hasUnreadFromFarmer ?? false,
            isActiveConversation: analysis.isActiveConversation,
            size: 14,
          ),
          const SizedBox(width: 4),
          // Unread count badge
          if ((analysis.unreadMessageCount ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${analysis.unreadMessageCount}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build plant image widget with network loading and fallback
  Widget _buildPlantImage(String? imageUrl) {
    if (imageUrl != null &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF3F4F6),
                    const Color(0xFFE5E7EB),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage();
          },
        ),
      );
    }
    return _buildFallbackImage();
  }

  /// Build fallback placeholder image
  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF3F4F6),
            const Color(0xFFE5E7EB),
          ],
        ),
      ),
      child: const Icon(
        Icons.local_florist,
        size: 48,
        color: Color(0xFF9CA3AF),
      ),
    );
  }

  /// Build health status badge (bottom-right corner)
  Widget _buildHealthBadge(BuildContext context) {
    final status = _getHealthStatus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }

  /// Get health status configuration based on score and severity
  _HealthStatus _getHealthStatus() {
    final score = analysis.overallHealthScore ?? 0;
    final severity = analysis.healthSeverity?.toLowerCase() ?? '';
    final primaryConcern = analysis.primaryConcern?.toLowerCase() ?? '';

    // Priority 1: Check severity
    if (severity.contains('critical') ||
        primaryConcern.contains('hastalık') ||
        primaryConcern.contains('disease')) {
      return _HealthStatus(
        label: 'Hastalık',
        backgroundColor: const Color(0xFFFEE2E2), // red-100
        textColor: const Color(0xFF991B1B), // red-800
      );
    } else if (severity.contains('moderate') ||
               primaryConcern.contains('dikkat') ||
               primaryConcern.contains('warning')) {
      return _HealthStatus(
        label: 'Dikkat',
        backgroundColor: const Color(0xFFFEF3C7), // yellow-100
        textColor: const Color(0xFF92400E), // yellow-800
      );
    }

    // Priority 2: Check health score
    if (score >= 80) {
      return _HealthStatus(
        label: 'Sağlıklı',
        backgroundColor: const Color(0xFFDCFCE7), // green-100
        textColor: const Color(0xFF166534), // green-800
      );
    } else if (score >= 60) {
      return _HealthStatus(
        label: 'Dikkat',
        backgroundColor: const Color(0xFFFEF3C7), // yellow-100
        textColor: const Color(0xFF92400E), // yellow-800
      );
    } else if (score > 0) {
      return _HealthStatus(
        label: 'Hastalık',
        backgroundColor: const Color(0xFFFEE2E2), // red-100
        textColor: const Color(0xFF991B1B), // red-800
      );
    }

    // Default: Analysis completed
    return _HealthStatus(
      label: 'Analiz Edildi',
      backgroundColor: const Color(0xFFE0E7FF), // blue-100
      textColor: const Color(0xFF1E40AF), // blue-800
    );
  }
}

class _HealthStatus {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _HealthStatus({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}
