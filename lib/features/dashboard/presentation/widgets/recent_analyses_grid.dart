import 'package:flutter/material.dart';
import '../../../plant_analysis/presentation/pages/analysis_results_screen.dart';

class RecentAnalysesGrid extends StatelessWidget {
  const RecentAnalysesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final analyses = _getMockAnalyses();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: analyses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
        imageUrl: 'assets/images/mock_plant1.jpg',
        description: 'Genel sağlık durumu iyi, büyüme oranları normal seviyede',
      ),
      AnalysisItem(
        id: '2',
        plantName: 'Mısır Tarlası',
        analysisDate: '3 gün önce',
        status: AnalysisStatus.warning,
        imageUrl: 'assets/images/mock_plant2.jpg',
        description: 'Hafif beslenme eksikliği tespit edildi, gübreleme önerisi',
      ),
      AnalysisItem(
        id: '3',
        plantName: 'Buğday Ürünü',
        analysisDate: '5 gün önce',
        status: AnalysisStatus.healthy,
        imageUrl: 'assets/images/mock_plant3.jpg',
        description: 'Mükemmel gelişim gösteriyor, hasat zamanı yaklaşıyor',
      ),
      AnalysisItem(
        id: '4',
        plantName: 'Soya Fasulyesi',
        analysisDate: '1 hafta önce',
        status: AnalysisStatus.disease,
        imageUrl: 'assets/images/mock_plant4.jpg',
        description: 'Fungal enfeksiyon riski, acil müdahale gerekiyor',
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
        // Navigate to analysis results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultsScreen(
              analysisId: analysis.id,
              imageUrl: analysis.imageUrl,
              confidence: _MockDataHelper.getConfidenceFromStatus(analysis.status),
              diseases: _MockDataHelper.getMockDiseases(analysis.status),
              recommendations: _MockDataHelper.getMockRecommendations(analysis.status),
              analysisDate: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ),
        );
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
            Container(
              height: 200,
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
            // Plant Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.plantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    analysis.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    analysis.analysisDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
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
  final String description;

  AnalysisItem({
    required this.id,
    required this.plantName,
    required this.analysisDate,
    required this.status,
    required this.imageUrl,
    required this.description,
  });
}

enum AnalysisStatus {
  healthy,
  warning,
  disease,
}

// Helper class for mock data generation
class _MockDataHelper {
  static double getConfidenceFromStatus(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.healthy:
        return 95.0;
      case AnalysisStatus.warning:
        return 78.0;
      case AnalysisStatus.disease:
        return 87.0;
    }
  }

  static List<DiseaseDetection> getMockDiseases(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.healthy:
        return [];
      case AnalysisStatus.warning:
        return [
          DiseaseDetection(
            name: 'Nutrient Deficiency',
            severity: 'Medium',
            confidence: 78.0,
          ),
        ];
      case AnalysisStatus.disease:
        return [
          DiseaseDetection(
            name: 'Fungal Infection',
            severity: 'High',
            confidence: 87.0,
          ),
        ];
    }
  }

  static List<TreatmentRecommendation> getMockRecommendations(AnalysisStatus status) {
    switch (status) {
      case AnalysisStatus.healthy:
        return [
          TreatmentRecommendation(
            name: 'Continue Current Care',
            description: 'Your plant is healthy! Continue with current watering and fertilization schedule.',
            isOrganic: true,
          ),
        ];
      case AnalysisStatus.warning:
        return [
          TreatmentRecommendation(
            name: 'Balanced Fertilizer',
            description: 'Apply balanced NPK fertilizer to address nutrient deficiency.',
            isOrganic: true,
          ),
          TreatmentRecommendation(
            name: 'Soil Test Kit',
            description: 'Test soil pH and nutrient levels for targeted treatment.',
            isOrganic: false,
          ),
        ];
      case AnalysisStatus.disease:
        return [
          TreatmentRecommendation(
            name: 'Neem Oil Treatment',
            description: 'Apply neem oil solution every 7 days until symptoms disappear.',
            isOrganic: true,
          ),
          TreatmentRecommendation(
            name: 'Copper Fungicide',
            description: 'Use copper-based fungicide for severe fungal infections.',
            isOrganic: false,
          ),
        ];
    }
  }
}