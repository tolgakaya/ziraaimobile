import 'package:flutter/material.dart';
import '../../data/models/sponsored_analysis_summary.dart';
import 'envelope_icon.dart';

/// Individual analysis card for sponsor with comprehensive information display
/// Image-first layout with message badge overlay + all analysis details
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
            // Image Section with Overlays
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
                  // Tier Badge (top-right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildTierBadge(context),
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

            // Plant Info Section with Enhanced Visual Design
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFFAFAFA),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant name with gradient background
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF0FDF4), // green-50
                            const Color(0xFFDCFCE7), // green-100
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF86EFAC).withOpacity(0.3), // green-300
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Plant icon
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 20,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  analysis.cropType ?? 'Bilinmeyen Bitki',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46), // green-800
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  analysis.analysisDateFormatted,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF059669), // green-600
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (analysis.hasBasicAccess && analysis.overallHealthScore != null)
                            _buildHealthScoreBadge(context),
                        ],
                      ),
                    ),

                    // Plant species and variety with subtle background
                    if (analysis.hasBasicAccess && analysis.plantSpecies != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB), // gray-50
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB), // gray-200
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.grass,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${analysis.plantSpecies}${analysis.plantVariety != null ? ' - ${analysis.plantVariety}' : ''}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151), // gray-700
                                  height: 1.3,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Growth stage with icon
                    if (analysis.hasBasicAccess && analysis.growthStage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF), // sky-50
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.spa, size: 14, color: Color(0xFF0EA5E9)), // sky-500
                            const SizedBox(width: 6),
                            Text(
                              analysis.growthStage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF075985), // sky-800
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Primary Concern with enhanced visual design
                    if (analysis.hasDetailedAccess && analysis.primaryConcern != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getSeverityColor(analysis.healthSeverity).withOpacity(0.08),
                              _getSeverityColor(analysis.healthSeverity).withOpacity(0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _getSeverityColor(analysis.healthSeverity).withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getSeverityColor(analysis.healthSeverity).withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(analysis.healthSeverity).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getSeverityIcon(analysis.healthSeverity),
                                size: 20,
                                color: _getSeverityColor(analysis.healthSeverity),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ana Sorun',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getSeverityColor(analysis.healthSeverity).withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    analysis.primaryConcern!,
                                    style: TextStyle(
                                      color: _getSeverityColor(analysis.healthSeverity),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Message Preview Section with enhanced design
                    if (analysis.hasMessages && analysis.lastMessagePreview != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: analysis.hasUnreadMessages
                                ? [
                                    const Color(0xFFDCEEFE), // blue-100
                                    const Color(0xFFBFDBFE), // blue-200
                                  ]
                                : [
                                    const Color(0xFFF9FAFB), // gray-50
                                    const Color(0xFFF3F4F6), // gray-100
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: analysis.hasUnreadMessages
                                ? const Color(0xFF60A5FA).withOpacity(0.4) // blue-400
                                : const Color(0xFFD1D5DB), // gray-300
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: analysis.hasUnreadMessages
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: analysis.hasUnreadMessages ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Son Mesaj',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: analysis.hasUnreadMessages
                                          ? Colors.blue[700]
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    analysis.lastMessagePreview!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: analysis.hasUnreadMessages ? Colors.black87 : Colors.grey[700],
                                      fontWeight: analysis.hasUnreadMessages ? FontWeight.w600 : FontWeight.normal,
                                      height: 1.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (analysis.lastMessageDate != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: analysis.hasUnreadMessages
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatMessageDate(analysis.lastMessageDate!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: analysis.hasUnreadMessages ? Colors.blue[700] : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Sponsor Branding with elegant design
                    if (analysis.canViewLogo == true && analysis.sponsorInfo?.logoUrl != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFAF5FF), // purple-50
                              Color(0xFFF3E8FF), // purple-100
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE9D5FF).withOpacity(0.5), // purple-200
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA855F7).withOpacity(0.1), // purple-500
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                size: 16,
                                color: Color(0xFFA855F7), // purple-500
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sponsorlu Analiz',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7E22CE), // purple-700
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Image.network(
                              analysis.sponsorInfo?.logoUrl ?? '',
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  analysis.sponsorInfo?.companyName ?? 'Sponsor',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7E22CE), // purple-700
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build compact message badge for image overlay (top-left)
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

  /// Build tier badge (top-right on image)
  Widget _buildTierBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTierColor(analysis.tierName ?? 'S'),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        analysis.tierName ?? 'S',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build health score badge (next to plant name)
  Widget _buildHealthScoreBadge(BuildContext context) {
    final score = analysis.overallHealthScore ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getHealthScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getHealthScoreColor(score).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: 12,
            color: _getHealthScoreColor(score),
          ),
          const SizedBox(width: 4),
          Text(
            analysis.healthScoreText,
            style: TextStyle(
              color: _getHealthScoreColor(score),
              fontSize: 11,
              fontWeight: FontWeight.bold,
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

  /// Build health status badge (bottom-right on image)
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

  /// Get tier color (S/M: blue, L: orange, XL: purple)
  Color _getTierColor(String tierName) {
    if (tierName.contains('S') && !tierName.contains('X')) {
      return const Color(0xFF3B82F6); // blue-500
    } else if (tierName.contains('M')) {
      return const Color(0xFF06B6D4); // cyan-500
    } else if (tierName == 'L') {
      return const Color(0xFFF97316); // orange-500
    } else if (tierName == 'XL') {
      return const Color(0xFFA855F7); // purple-500
    }
    return const Color(0xFF6B7280); // gray-500
  }

  /// Get health score color (green: 80+, orange: 60-79, red: 0-59)
  Color _getHealthScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981); // green-500
    if (score >= 60) return const Color(0xFFF59E0B); // amber-500
    return const Color(0xFFEF4444); // red-500
  }

  /// Get severity color
  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'healthy':
        return const Color(0xFF10B981); // green-500
      case 'moderate':
        return const Color(0xFFF59E0B); // amber-500
      case 'critical':
        return const Color(0xFFEF4444); // red-500
      default:
        return const Color(0xFF6B7280); // gray-500
    }
  }

  /// Get severity icon
  IconData _getSeverityIcon(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'moderate':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  /// Format message date in Turkish-friendly format
  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${date.day}/${date.month}';
    }
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
