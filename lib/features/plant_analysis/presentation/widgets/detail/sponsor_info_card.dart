import 'package:flutter/material.dart';

class SponsorInfoCard extends StatelessWidget {
  final String sponsorId;

  const SponsorInfoCard({
    Key? key,
    required this.sponsorId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: const Color(0xFFF0F9FF), // Light blue background
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sponsor Desteği',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0C4A6E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bu analiz $sponsorId sponsor desteğiyle gerçekleştirildi',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0C4A6E),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.verified,
              color: const Color(0xFF0EA5E9),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}