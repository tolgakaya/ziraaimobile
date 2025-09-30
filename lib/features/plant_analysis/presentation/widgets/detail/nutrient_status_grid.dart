import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class NutrientStatusGrid extends StatelessWidget {
  final NutrientStatusDto status;

  const NutrientStatusGrid({
    Key? key,
    required this.status,
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
                  Icons.science,
                  color: Color(0xFF17CF17),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Besin Durumu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(status.severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getSeverityColor(status.severity).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    status.severity,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getSeverityColor(status.severity),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Primary Deficiency
            if (status.primaryDeficiency != null && status.primaryDeficiency!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ana Eksiklik: ${status.primaryDeficiency}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Nutrient Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                _buildNutrientTile('Azot (N)', status.nitrogen),
                _buildNutrientTile('Fosfor (P)', status.phosphorus),
                _buildNutrientTile('Potasyum (K)', status.potassium),
                _buildNutrientTile('Kalsiyum', status.calcium),
                _buildNutrientTile('Magnezyum', status.magnesium),
                _buildNutrientTile('Kükürt', status.sulfur),
                _buildNutrientTile('Demir', status.iron),
                _buildNutrientTile('Çinko', status.zinc),
                _buildNutrientTile('Mangan', status.manganese),
                _buildNutrientTile('Bor', status.boron),
                _buildNutrientTile('Bakır', status.copper),
                _buildNutrientTile('Molibden', status.molybdenum),
              ],
            ),
            
            // Secondary Deficiencies
            if (status.secondaryDeficiencies != null && status.secondaryDeficiencies!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'İkincil Eksiklikler',
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
                children: status.secondaryDeficiencies!.map((deficiency) {
                  return Chip(
                    label: Text(
                      deficiency,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange.shade50,
                    side: BorderSide(color: Colors.orange.shade200),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientTile(String name, String status) {
    Color statusColor = _getNutrientStatusColor(status);
    IconData statusIcon = _getNutrientStatusIcon(status);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getNutrientStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'eksik':
      case 'çok eksik':
        return Colors.red;
      case 'düşük':
        return Colors.orange;
      case 'normal':
      case 'yeterli':
        return Colors.green;
      case 'yüksek':
      case 'fazla':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNutrientStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'eksik':
      case 'çok eksik':
        return Icons.trending_down;
      case 'düşük':
        return Icons.remove;
      case 'normal':
      case 'yeterli':
        return Icons.check_circle;
      case 'yüksek':
      case 'fazla':
        return Icons.trending_up;
      default:
        return Icons.help_outline;
    }
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