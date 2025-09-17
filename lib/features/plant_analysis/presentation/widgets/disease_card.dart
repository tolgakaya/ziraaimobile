import 'package:flutter/material.dart';
import '../../data/models/plant_disease.dart';

class DiseaseCard extends StatelessWidget {
  final PlantDisease disease;

  const DiseaseCard({
    Key? key,
    required this.disease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(disease.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bug_report,
                    color: _getSeverityColor(disease.severity),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disease.name ?? 'Bilinmeyen Hastalık',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (disease.severity != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(disease.severity).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getSeverityText(disease.severity!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getSeverityColor(disease.severity),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (disease.confidence != null) ...[
                  Column(
                    children: [
                      Text(
                        '%${(disease.confidence! * 100).toInt()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        'Güven',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (disease.description != null) ...[
              const SizedBox(height: 12),
              Text(
                disease.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
            if (disease.symptoms != null && disease.symptoms!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Belirtiler:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...disease.symptoms!.map((symptom) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        symptom,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (disease.affectedParts != null && disease.affectedParts!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: disease.affectedParts!.map((part) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    part,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'yüksek':
      case 'high':
      case 'kritik':
      case 'critical':
        return const Color(0xFFE53935);
      case 'orta':
      case 'medium':
      case 'moderate':
        return const Color(0xFFFFA726);
      case 'düşük':
      case 'low':
      case 'hafif':
      case 'mild':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return 'Yüksek Risk';
      case 'critical':
        return 'Kritik';
      case 'medium':
      case 'moderate':
        return 'Orta Risk';
      case 'low':
      case 'mild':
        return 'Düşük Risk';
      default:
        return severity;
    }
  }
}