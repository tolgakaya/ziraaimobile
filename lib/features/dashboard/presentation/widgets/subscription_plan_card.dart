import 'package:flutter/material.dart';
import 'dart:math' as math;

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mevcut Plan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Temel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          TextSpan(
                            text: '72',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          TextSpan(text: '/100 analiz kullanıldı'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          TextSpan(
                            text: '12',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          TextSpan(text: ' gün kaldı'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Circle
              const SizedBox(width: 16),
              const _CircularProgress(
                progress: 0.72,
                size: 64,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to upgrade plans
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDCFCE7), // primary-100
                foregroundColor: const Color(0xFF15803D), // primary-700
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Planı Yükselt',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: const Color(0xFF15803D),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double progress;
  final double size;

  const _CircularProgress({
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background Circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              color: const Color(0xFFE5E7EB), // gray-200
              strokeWidth: 3,
            ),
          ),
          // Progress Circle
          CustomPaint(
            size: Size(size, size),
            painter: _CirclePainter(
              color: const Color(0xFF22C55E), // primary-500
              strokeWidth: 3,
              progress: progress,
            ),
          ),
          // Center Text
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double? progress;

  _CirclePainter({
    required this.color,
    required this.strokeWidth,
    this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    if (progress == null) {
      // Draw full circle (background)
      canvas.drawCircle(center, radius, paint);
    } else {
      // Draw progress arc
      const startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * progress!;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}