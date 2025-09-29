import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class CrossFactorInsights extends StatelessWidget {
  final List<CrossFactorInsightDto> insights;

  const CrossFactorInsights({
    Key? key,
    required this.insights,
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
                  Icons.insights,
                  color: Color(0xFF7C3AED),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Çapraz Faktör Analizleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightItem(insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(CrossFactorInsightDto insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getImpactColor(insight.impactLevel).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getImpactColor(insight.impactLevel).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: _getImpactColor(insight.impactLevel),
                size: 18,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getImpactColor(insight.impactLevel),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  insight.impactLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(insight.confidence),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '%${(insight.confidence * 100).toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.insight,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111811),
              height: 1.4,
            ),
          ),
          if (insight.affectedAspects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: insight.affectedAspects.map((aspect) {
                return Chip(
                  label: Text(
                    _translateAspect(aspect),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.purple.shade50,
                  side: BorderSide(color: Colors.purple.shade200),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _translateAspect(String aspect) {
    switch (aspect.toLowerCase()) {
      case 'disease_symptoms':
        return 'Hastalık Belirtileri';
      case 'nutrient_status':
        return 'Besin Durumu';
      case 'environmental_stress':
        return 'Çevresel Stres';
      case 'growth_pattern':
        return 'Büyüme Deseni';
      default:
        return aspect;
    }
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'yüksek':
      case 'high':
        return Colors.red;
      case 'orta':
      case 'medium':
        return Colors.orange;
      case 'düşük':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}