import 'package:flutter/material.dart';

class FarmerSummaryCard extends StatelessWidget {
  final String summary;

  const FarmerSummaryCard({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFFE8F5E8), // Light green background
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
                    color: const Color(0xFF17CF17),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Çiftçi Dostu Özet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F5132),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF0F5132),
              ),
            ),
          ],
        ),
      ),
    );
  }
}