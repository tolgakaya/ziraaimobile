import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class RiskAssessmentCard extends StatelessWidget {
  final RiskAssessmentDto assessment;

  const RiskAssessmentCard({
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
                Icon(
                  Icons.warning_amber_rounded,
                  color: _getRiskColor(assessment.yieldLossProbability),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Risk Değerlendirmesi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Risk items
            _buildRiskItem(
              'Verim Kaybı Olasılığı',
              assessment.yieldLossProbability,
              Icons.trending_down,
            ),
            const SizedBox(height: 12),
            _buildRiskItem(
              'Kötüleşme Süresi',
              assessment.timelineToWorsen,
              Icons.schedule,
            ),
            const SizedBox(height: 12),
            _buildRiskItem(
              'Yayılma Potansiyeli',
              assessment.spreadPotential,
              Icons.open_in_full,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRiskColor(value).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getRiskColor(value).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getRiskColor(value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'yüksek':
      case 'kritik':
      case 'acil':
        return Colors.red;
      case 'orta':
      case 'normal':
        return Colors.orange;
      case 'düşük':
      case 'az':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}