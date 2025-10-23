import 'package:flutter/material.dart';
import '../../../plant_analysis/data/models/analysis_list_response.dart';
import '../../../sponsorship/presentation/widgets/envelope_icon.dart';
import '../../../sponsorship/presentation/widgets/unread_badge.dart';

/// Individual analysis card for farmer dashboard with messaging UI
/// Similar to SponsoredAnalysisCard but for farmer perspective
class FarmerAnalysisCard extends StatelessWidget {
  final AnalysisSummary analysis;
  final VoidCallback onTap;

  const FarmerAnalysisCard({
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
                    child: _buildPlantImage(analysis.thumbnailUrl),
                  ),
                  // Health Status Badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildHealthBadge(context),
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
                          analysis.plantType ?? 'Bilinmeyen Bitki',
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
                        _formatDate(analysis.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  if (analysis.healthStatus != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      analysis.healthStatus!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Messaging section (if messages exist)
                  if (analysis.hasMessages) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: analysis.hasUnreadMessages
                            ? Colors.blue.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: analysis.hasUnreadMessages
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Envelope icon
                          EnvelopeIcon(
                            hasMessages: analysis.hasMessages,
                            hasUnreadMessages: analysis.hasUnreadMessages,
                            hasUnreadFromFarmer: analysis.hasUnreadFromSponsor ?? false, // FARMER: Check from sponsor
                            isActiveConversation: analysis.isActiveConversation,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          // Message preview
                          Expanded(
                            child: Text(
                              analysis.lastMessagePreview ?? 'Mesaj var',
                              style: TextStyle(
                                fontSize: 12,
                                color: analysis.hasUnreadMessages
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: analysis.hasUnreadMessages
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Unread badge
                          UnreadBadge(
                            unreadCount: analysis.unreadMessageCount,
                            hasUnreadFromFarmer: analysis.hasUnreadFromSponsor ?? false, // FARMER: Check from sponsor
                            size: 16,
                          ),
                        ],
                      ),
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

  /// Build health status badge
  Widget _buildHealthBadge(BuildContext context) {
    final status = _getHealthStatus(analysis.healthStatus);

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

  /// Get health status configuration
  _HealthStatus _getHealthStatus(String? healthStatus) {
    final status = healthStatus?.toLowerCase() ?? '';

    if (status.contains('sağlıklı') || status.contains('healthy') || status.contains('iyi')) {
      return _HealthStatus(
        label: 'Sağlıklı',
        backgroundColor: const Color(0xFFDCFCE7), // green-100
        textColor: const Color(0xFF166534), // green-800
      );
    } else if (status.contains('dikkat') || status.contains('warning') || status.contains('uyarı')) {
      return _HealthStatus(
        label: 'Dikkat',
        backgroundColor: const Color(0xFFFEF3C7), // yellow-100
        textColor: const Color(0xFF92400E), // yellow-800
      );
    } else if (status.contains('hastalık') || status.contains('disease') || status.contains('problem')) {
      return _HealthStatus(
        label: 'Hastalık',
        backgroundColor: const Color(0xFFFEE2E2), // red-100
        textColor: const Color(0xFF991B1B), // red-800
      );
    } else {
      return _HealthStatus(
        label: 'Analiz Edildi',
        backgroundColor: const Color(0xFFE0E7FF), // blue-100
        textColor: const Color(0xFF1E40AF), // blue-800
      );
    }
  }

  /// Format date in Turkish-friendly format
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} hafta önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
