import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../subscription/services/subscription_service.dart';
import '../../../subscription/presentation/screens/subscription_status_screen.dart';
import 'package:dio/dio.dart';

class SubscriptionPlanCard extends StatefulWidget {
  final VoidCallback? onNavigateToSubscription;
  final bool isCompact;
  
  const SubscriptionPlanCard({
    super.key,
    this.onNavigateToSubscription,
    this.isCompact = false,
  });

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when coming back to this screen
    setState(() {
      _subscriptionFuture = _loadSubscriptionData();
    });
  }

  Future<Map<String, dynamic>?> _loadSubscriptionData() async {
    try {
      print('🔄 Loading subscription data...');
      
      final networkClient = getIt<NetworkClient>();
      final secureStorage = getIt<SecureStorageService>();
      
      // Get token
      final token = await secureStorage.getToken();
      if (token == null) {
        print('❌ No token available');
        return null;
      }

      print('✅ Token found, making API request...');
      
      // Make API request
      final response = await networkClient.get(
        ApiConfig.usageStatus,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📡 API Response: ${response.statusCode}');
      print('📊 API Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          print('✅ Subscription data loaded successfully');
          return data;
        }
      }
      
      print('⚠️ API returned null data');
      return null;
    } catch (e) {
      print('❌ Error loading subscription data: $e');
      return null;
    }
  }

  int? _calculateDaysLeft(String? endDateString) {
    if (endDateString == null) return null;
    
    try {
      final endDate = DateTime.parse(endDateString);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      print('Error parsing date: $e');
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
            gradient: widget.isCompact 
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1), // indigo-500
                    Color(0xFF4F46E5), // indigo-600
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF), // white
                    Color(0xFFF8FAFC), // slate-50
                  ],
                ),
            borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 20),
            border: widget.isCompact 
              ? null 
              : Border.all(
                  color: const Color(0xFFE2E8F0), // slate-200
                  width: 1,
                ),
            boxShadow: widget.isCompact 
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onNavigateToSubscription ?? () async {
                // Navigate to subscription status screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionStatusScreen(),
                  ),
                );
                
                // Refresh the subscription data after returning
                if (result == true && mounted) {
                  setState(() {
                    _subscriptionFuture = _loadSubscriptionData();
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(widget.isCompact ? 16 : 20),
                child: widget.isCompact 
                  ? _buildCompactView(planName, usedCount, totalCount, progress) 
                  : _buildFullView(planName, usedCount, totalCount, daysLeft, progress),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactView(String planName, int usedCount, int totalCount, double progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          planName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '$usedCount/$totalCount',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFullView(String planName, int usedCount, int totalCount, int daysLeft, double progress) {
    return Column(
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
                  padding: const EdgeInsets.all(4),
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
      ],
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
      child: CustomPaint(
        painter: _CircularProgressPainter(progress),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;

  _CircularProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background circle
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Progress text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).round()}%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}