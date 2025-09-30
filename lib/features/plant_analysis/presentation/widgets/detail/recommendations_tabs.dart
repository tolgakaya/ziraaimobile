import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class RecommendationsTabs extends StatelessWidget {
  final RecommendationsDto recommendations;

  const RecommendationsTabs({
    Key? key,
    required this.recommendations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.recommend,
                    color: Color(0xFF17CF17),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Öneriler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111811),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            TabBar(
              labelColor: const Color(0xFF17CF17),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFF17CF17),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency, size: 16),
                      const SizedBox(width: 4),
                      Text('Acil (${recommendations.immediate.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Text('Kısa (${recommendations.shortTerm.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield, size: 16),
                      const SizedBox(width: 4),
                      Text('Önleyici (${recommendations.preventive.length})'),
                    ],
                  ),
                ),
              ],
            ),
            
            // Tab Views
            Container(
              height: _calculateTabViewHeight(),
              child: TabBarView(
                children: [
                  _buildRecommendationsList(recommendations.immediate, Colors.red),
                  _buildRecommendationsList(recommendations.shortTerm, Colors.orange),
                  _buildRecommendationsList(recommendations.preventive, Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(List<RecommendationItemDto> items, Color themeColor) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Bu kategoride öneri bulunmuyor',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by priority
    final sortedItems = List<RecommendationItemDto>.from(items);
    sortedItems.sort((a, b) => b.priorityValue.compareTo(a.priorityValue));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedItems.length,
      itemBuilder: (context, index) {
        return _buildRecommendationItem(sortedItems[index], themeColor);
      },
    );
  }

  Widget _buildRecommendationItem(RecommendationItemDto item, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getPriorityColor(item.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getPriorityIcon(item.priority),
                size: 16,
                color: _getPriorityColor(item.priority),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.action,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111811),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(item.priority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.priority,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.timeline,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.details,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111811),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'kritik':
        return Colors.red.shade700;
      case 'yüksek':
        return Colors.red.shade500;
      case 'orta':
        return Colors.orange.shade600;
      case 'düşük':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'kritik':
        return Icons.priority_high;
      case 'yüksek':
        return Icons.warning;
      case 'orta':
        return Icons.info;
      case 'düşük':
        return Icons.low_priority;
      default:
        return Icons.help_outline;
    }
  }

  double _calculateTabViewHeight() {
    // Calculate approximate height based on content
    int maxItems = [
      recommendations.immediate.length,
      recommendations.shortTerm.length,
      recommendations.preventive.length,
    ].reduce((a, b) => a > b ? a : b);

    if (maxItems == 0) return 150; // Empty state height
    
    // Each item is approximately 100px (collapsed) + padding
    double estimatedHeight = (maxItems * 110.0) + 32; // 32 for padding
    
    // Limit maximum height
    return estimatedHeight.clamp(200.0, 500.0);
  }
}