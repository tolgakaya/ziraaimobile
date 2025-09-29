import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class HealthAssessmentCard extends StatelessWidget {
  final HealthAssessmentDto assessment;

  const HealthAssessmentCard({
    Key? key,
    required this.assessment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety,
                  color: Color(0xFF17CF17),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sağlık Değerlendirmesi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
                const Spacer(),
                _buildVigorScoreBadge(assessment.vigorScore),
              ],
            ),
            const SizedBox(height: 16),
            
            // Severity badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSeverityColor(assessment.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getSeverityColor(assessment.severity).withOpacity(0.3),
                ),
              ),
              child: Text(
                'Şiddet: ${assessment.severity}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getSeverityColor(assessment.severity),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Assessment details
            _buildDetailSection('Yaprak Rengi', assessment.leafColor),
            const SizedBox(height: 12),
            _buildDetailSection('Yaprak Dokusu', assessment.leafTexture),
            const SizedBox(height: 12),
            _buildDetailSection('Büyüme Deseni', assessment.growthPattern),
            const SizedBox(height: 12),
            _buildDetailSection('Yapısal Bütünlük', assessment.structuralIntegrity),
            
            // Stress indicators
            if (assessment.stressIndicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Stres Göstergeleri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: assessment.stressIndicators.map((indicator) {
                  return Chip(
                    label: Text(
                      indicator,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade200),
                  );
                }).toList(),
              ),
            ],
            
            // Disease symptoms
            if (assessment.diseaseSymptoms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Hastalık Belirtileri',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...assessment.diseaseSymptoms.map((symptom) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          symptom,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF111811),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildVigorScoreBadge(int score) {
    Color color = _getVigorScoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monitor_heart, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '$score/10',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getVigorScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.lime;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'yüksek':
      case 'kritik':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'düşük':
      case 'hafif':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}