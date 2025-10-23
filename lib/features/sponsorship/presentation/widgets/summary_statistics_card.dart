import 'package:flutter/material.dart';
import '../../data/models/sponsored_analyses_list_response.dart';

/// Summary statistics card showing aggregate metrics
/// Displays at the top of sponsored analyses list
class SummaryStatisticsCard extends StatelessWidget {
  final SponsoredAnalysesListSummary summary;

  const SummaryStatisticsCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Özet İstatistikler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            // First row: Total analyses and average health
            Row(
              children: [
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.analytics,
                    label: 'Toplam Analiz',
                    value: summary.totalAnalyses.toString(),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.favorite,
                    label: 'Ort. Sağlık',
                    value: '${summary.averageHealthScore.toStringAsFixed(1)}%',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Second row: This month and top crop
            Row(
              children: [
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.calendar_today,
                    label: 'Bu Ay',
                    value: summary.analysesThisMonth.toString(),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatisticItem(
                    icon: Icons.spa,
                    label: 'En Popüler',
                    value: summary.topCropTypes.isNotEmpty
                        ? summary.topCropTypes.first
                        : 'N/A',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            // Third row: Messaging statistics (if available)
            if (summary.analysesWithUnread != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatisticItem(
                      icon: Icons.mail,
                      label: 'Okunmamış Mesajlı',
                      value: summary.analysesWithUnread.toString(),
                      color: Colors.red,
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Individual statistic item widget
class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
