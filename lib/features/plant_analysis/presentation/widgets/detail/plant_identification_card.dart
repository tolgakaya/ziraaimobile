import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class PlantIdentificationCard extends StatelessWidget {
  final PlantIdentificationDto identification;

  const PlantIdentificationCard({
    Key? key,
    required this.identification,
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
                  Icons.local_florist,
                  color: Color(0xFF17CF17),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bitki Tanımlama',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
                const Spacer(),
                _buildConfidenceBadge(identification.confidence),
              ],
            ),
            const SizedBox(height: 16),
            
            // Species
            _buildInfoRow('Tür', identification.species),
            const SizedBox(height: 8),
            
            // Variety
            if (identification.variety != null && identification.variety!.isNotEmpty)
              _buildInfoRow('Çeşit', identification.variety!),
            const SizedBox(height: 8),
            
            // Growth Stage
            _buildInfoRow('Büyüme Aşaması', identification.growthStage),
            const SizedBox(height: 16),
            
            // Visible Parts
            if (identification.visibleParts.isNotEmpty) ...[
              Text(
                'Görünen Kısımlar',
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
                children: identification.visibleParts.map((part) {
                  return Chip(
                    label: Text(
                      part,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade200),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Identifying Features
            if (identification.identifyingFeatures.isNotEmpty) ...[
              Text(
                'Tanımlayıcı Özellikler',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              ...identification.identifyingFeatures.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 6,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111811),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color = _getConfidenceColor(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '%${confidence.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }
}