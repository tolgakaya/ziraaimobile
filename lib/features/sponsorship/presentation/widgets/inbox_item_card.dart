import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/sponsorship_inbox_item.dart';
import 'status_badge.dart';

/// Inbox item card widget
/// Displays sponsorship code details in a card format
class InboxItemCard extends StatelessWidget {
  final SponsorshipInboxItem item;
  final VoidCallback? onRedeemTap;

  const InboxItemCard({
    super.key,
    required this.item,
    this.onRedeemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Code and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Code with icon
                Row(
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.code,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),

                // Status badge
                StatusBadge(
                  status: item.status,
                  isUrgent: item.isUrgent,
                  daysUntilExpiry: item.daysUntilExpiry,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sponsor name
            Text(
              item.sponsorName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 8),

            // Details row: Tier, Channel, Date
            Row(
              children: [
                _buildDetailChip(
                  icon: Icons.workspace_premium,
                  label: item.tierName,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: item.sentVia == 'SMS' ? Icons.sms : Icons.chat,
                  label: item.sentVia,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                _buildDetailChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(item.sentDate),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),

            // Redeem button (only for active codes)
            if (item.isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRedeemTap,
                  icon: const Icon(Icons.redeem),
                  label: const Text('Abonelik kodunu kullan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // Used date (only for used codes)
            if (item.isUsed && item.usedDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kullanıldı: ${_formatDate(item.usedDate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'tr_TR').format(date);
  }
}
