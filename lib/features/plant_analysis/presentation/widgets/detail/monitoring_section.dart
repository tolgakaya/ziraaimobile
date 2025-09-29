import 'package:flutter/material.dart';
import '../../../data/models/plant_analysis_detail_dto.dart';

class MonitoringSection extends StatelessWidget {
  final List<MonitoringDto> monitoring;

  const MonitoringSection({
    Key? key,
    required this.monitoring,
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
                  Icons.monitor,
                  color: Color(0xFF059669),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'İzleme Parametreleri',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111811),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...monitoring.map((item) => _buildMonitoringItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringItem(MonitoringDto item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.parameter,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'Sıklık: ${item.frequency}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.rule,
                size: 16,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Eşik: ${item.threshold}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}