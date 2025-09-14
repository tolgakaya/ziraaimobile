import 'package:flutter/material.dart';

class RecentAnalysesGrid extends StatelessWidget {
  const RecentAnalysesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final analyses = _getMockAnalyses();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: analyses.length,
      itemBuilder: (context, index) {
        final analysis = analyses[index];
        return _AnalysisCard(analysis: analysis);
      },
    );
  }

  List<AnalysisItem> _getMockAnalyses() {
    return [
      AnalysisItem(
        id: '1',
        plantName: 'Domates Bitkisi',
        analysisDate: '2 gün önce',
        status: AnalysisStatus.healthy,
        imageUrl: 'assets/images/mock_plant1.jpg', // Mock image path
      ),
      AnalysisItem(
        id: '2',
        plantName: 'Mısır Tarlası',
        analysisDate: '3 gün önce',
        status: AnalysisStatus.warning,
        imageUrl: 'assets/images/mock_plant2.jpg',
      ),
      AnalysisItem(
        id: '3',
        plantName: 'Buğday Ürünü',
        analysisDate: '5 gün önce',
        status: AnalysisStatus.healthy,
        imageUrl: 'assets/images/mock_plant3.jpg',
      ),
      AnalysisItem(
        id: '4',
        plantName: 'Soya Fasulyesi',
        analysisDate: '1 hafta önce',
        status: AnalysisStatus.disease,
        imageUrl: 'assets/images/mock_plant4.jpg',
      ),
    ];
  }
}

class _AnalysisCard extends StatelessWidget {
  final AnalysisItem analysis;

  const _AnalysisCard({
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to analysis details
      },
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
            // Image Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: const Color(0xFFF3F4F6), // Placeholder color
                ),
                child: Stack(
                  children: [
                    // Plant Image (using placeholder for now)
                    Container(
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
                    ),
                    // Status Badge
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _StatusBadge(status: analysis.status),
                    ),
                  ],
                ),
              ),
            ),
            // Plant Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.plantName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    analysis.analysisDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AnalysisStatus status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusConfig.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusConfig.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: statusConfig.textColor,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.healthy:
        return _StatusConfig(
          label: 'Sağlıklı',
          backgroundColor: const Color(0xFFDCFCE7), // green-100
          textColor: const Color(0xFF166534), // green-800
        );
      case AnalysisStatus.warning:
        return _StatusConfig(
          label: 'Dikkat',
          backgroundColor: const Color(0xFFFEF3C7), // yellow-100
          textColor: const Color(0xFF92400E), // yellow-800
        );
      case AnalysisStatus.disease:
        return _StatusConfig(
          label: 'Hastalık',
          backgroundColor: const Color(0xFFFEE2E2), // red-100
          textColor: const Color(0xFF991B1B), // red-800
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

// Data Models
class AnalysisItem {
  final String id;
  final String plantName;
  final String analysisDate;
  final AnalysisStatus status;
  final String imageUrl;

  AnalysisItem({
    required this.id,
    required this.plantName,
    required this.analysisDate,
    required this.status,
    required this.imageUrl,
  });
}

enum AnalysisStatus {
  healthy,
  warning,
  disease,
}