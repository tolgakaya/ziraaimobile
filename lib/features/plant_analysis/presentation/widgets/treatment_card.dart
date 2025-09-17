import 'package:flutter/material.dart';
import '../../data/models/plant_treatment.dart';

class TreatmentCard extends StatelessWidget {
  final PlantTreatment treatment;

  const TreatmentCard({
    Key? key,
    required this.treatment,
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
                    color: _getTypeColor(treatment.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(treatment.type),
                    color: _getTypeColor(treatment.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment.name ?? 'Tedavi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (treatment.type != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getTypeText(treatment.type!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTypeColor(treatment.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (treatment.priority != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(treatment.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getPriorityColor(treatment.priority),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getPriorityText(treatment.priority!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(treatment.priority),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (treatment.description != null) ...[
              const SizedBox(height: 12),
              Text(
                treatment.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
            if (treatment.applicationMethod != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uygulama Yöntemi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      treatment.applicationMethod!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (treatment.products != null && treatment.products!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Önerilen Ürünler:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: treatment.products!.map((product) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_pharmacy,
                        size: 14,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ],
            if (treatment.frequency != null || treatment.duration != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (treatment.frequency != null) ...[
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sıklık: ${treatment.frequency}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (treatment.duration != null) ...[
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Süre: ${treatment.duration}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (treatment.precautions != null && treatment.precautions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.orange[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Önlemler',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...treatment.precautions!.map((precaution) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.arrow_right,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              precaution,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'kimyasal':
      case 'chemical':
        return const Color(0xFFE53935);
      case 'organik':
      case 'organic':
        return const Color(0xFF43A047);
      case 'biyolojik':
      case 'biological':
        return const Color(0xFF1E88E5);
      case 'kültürel':
      case 'cultural':
        return const Color(0xFF8E24AA);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'kimyasal':
      case 'chemical':
        return Icons.science;
      case 'organik':
      case 'organic':
        return Icons.eco;
      case 'biyolojik':
      case 'biological':
        return Icons.biotech;
      case 'kültürel':
      case 'cultural':
        return Icons.agriculture;
      default:
        return Icons.healing;
    }
  }

  String _getTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'chemical':
        return 'Kimyasal Tedavi';
      case 'organic':
        return 'Organik Tedavi';
      case 'biological':
        return 'Biyolojik Tedavi';
      case 'cultural':
        return 'Kültürel Önlemler';
      default:
        return type;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'yüksek':
      case 'high':
      case 'acil':
      case 'urgent':
        return const Color(0xFFE53935);
      case 'orta':
      case 'medium':
      case 'normal':
        return const Color(0xFFFFA726);
      case 'düşük':
      case 'low':
        return const Color(0xFF66BB6A);
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return 'ACİL';
      case 'medium':
      case 'normal':
        return 'NORMAL';
      case 'low':
        return 'DÜŞÜK';
      default:
        return priority.toUpperCase();
    }
  }
}