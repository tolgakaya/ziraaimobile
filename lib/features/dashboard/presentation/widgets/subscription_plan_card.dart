import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../subscription/services/subscription_service.dart';
import '../../../subscription/presentation/screens/subscription_status_screen.dart';
import 'package:dio/dio.dart';

class SubscriptionPlanCard extends StatefulWidget {
  const SubscriptionPlanCard({super.key});

  @override
  State<SubscriptionPlanCard> createState() => _SubscriptionPlanCardState();
}

class _SubscriptionPlanCardState extends State<SubscriptionPlanCard> {
  late Future<Map<String, dynamic>?> _subscriptionFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionFuture = _loadSubscriptionData();
  }

  Future<Map<String, dynamic>?> _loadSubscriptionData() async {
    try {
      print('🔵 SubscriptionPlanCard: Loading subscription data...');
      final networkClient = getIt<NetworkClient>();
      final secureStorage = getIt<SecureStorageService>();
      final token = await secureStorage.getToken();

      if (token == null) {
        print('⚠️ SubscriptionPlanCard: No token found');
        return null;
      }

      print('🔵 SubscriptionPlanCard: Calling ${ApiConfig.usageStatus}');
      print('🔵 SubscriptionPlanCard: Full URL will be: ${networkClient.dio.options.baseUrl}${ApiConfig.usageStatus}');
      final response = await networkClient.get(
        ApiConfig.usageStatus,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error loading subscription data: $e');
      return null;
    }
  }

  int? _calculateDaysLeft(String? renewalDate) {
    if (renewalDate == null) return null;

    try {
      final renewal = DateTime.parse(renewalDate);
      final now = DateTime.now();
      final difference = renewal.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _subscriptionFuture,
      builder: (context, snapshot) {
        // Get data from API or use defaults (fallback to static for now)
        final subscriptionData = snapshot.data;
        print('🔍 Subscription data: $subscriptionData');

        final planName = subscriptionData?['tierName'] ?? 'Temel';
        final usedCount = subscriptionData?['dailyUsed'] ?? 5;
        final totalCount = subscriptionData?['dailyLimit'] ?? 50;
        final daysLeft = _calculateDaysLeft(subscriptionData?['subscriptionEndDate']) ?? 15;
        final progress = totalCount > 0 ? (usedCount / totalCount).clamp(0.0, 1.0) : 0.1;

        return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF), // white
            Color(0xFFF8FAFC), // slate-50
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // slate-200
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          TextSpan(
                            text: '$usedCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          TextSpan(text: '/$totalCount analiz kullanıldı'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        children: [
                          TextSpan(
                            text: '$daysLeft',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const TextSpan(text: ' gün kaldı'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Circle
              const SizedBox(width: 16),
              _CircularProgress(
                progress: progress.clamp(0.0, 1.0),
                size: 64,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Upgrade Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1), // indigo-500
                  Color(0xFF4F46E5), // indigo-600
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to subscription status screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionStatusScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Planı Yükselt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
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