import 'package:flutter/material.dart';

class ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const ConfidenceBadge({
    Key? key,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toInt();
    final color = _getColorForConfidence(confidence);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForConfidence(confidence),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '%$percentage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForConfidence(double confidence) {
    if (confidence >= 0.8) {
      return const Color(0xFF2E7D32);
    } else if (confidence >= 0.6) {
      return const Color(0xFFFFA726);
    } else {
      return const Color(0xFFE53935);
    }
  }

  IconData _getIconForConfidence(double confidence) {
    if (confidence >= 0.8) {
      return Icons.check_circle;
    } else if (confidence >= 0.6) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }
}