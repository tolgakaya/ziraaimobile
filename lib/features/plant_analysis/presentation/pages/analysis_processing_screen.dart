import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../../data/repositories/plant_analysis_repository.dart';
import '../../data/models/plant_analysis_response.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/error/plant_analysis_exceptions.dart';
import '../../../../core/widgets/error_widgets.dart';
import 'analysis_results_screen.dart';

class AnalysisProcessingScreen extends StatefulWidget {
  final String analysisId;
  final File selectedImage;
  final String? estimatedTime;
  final int? queuePosition;

  const AnalysisProcessingScreen({
    super.key,
    required this.analysisId,
    required this.selectedImage,
    this.estimatedTime,
    this.queuePosition,
  });

  @override
  State<AnalysisProcessingScreen> createState() => _AnalysisProcessingScreenState();
}

class _AnalysisProcessingScreenState extends State<AnalysisProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late final PlantAnalysisRepository _repository;

  StreamSubscription<AnalysisStatusUpdate>? _statusSubscription;
  String _currentStatus = 'İşleniyor...';
  PlantAnalysisException? _currentError;
  int? _currentQueuePosition;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Use GetIt for dependency injection
    _repository = getIt<PlantAnalysisRepository>();

    // Rotation animation for the processing indicator
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Initialize queue position
    _currentQueuePosition = widget.queuePosition;

    // Start polling for analysis results
    _startPolling();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _statusSubscription?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _statusSubscription = _repository
        .pollAnalysisResult(
          widget.analysisId,
          interval: const Duration(seconds: 3),
          timeout: const Duration(minutes: 15),
        )
        .listen(
          _handleStatusUpdate,
          onError: _handleError,
        );
  }

  void _handleStatusUpdate(AnalysisStatusUpdate update) {
    if (!mounted) return;

    setState(() {
      if (update.isProcessing) {
        _currentStatus = 'Analiz devam ediyor...';
        // Simulate queue position updates
        if (_currentQueuePosition != null && _currentQueuePosition! > 1) {
          _currentQueuePosition = _currentQueuePosition! - 1;
        }
      } else if (update.isCompleted && update.result != null) {
        _currentStatus = 'Analiz tamamlandı!';
        _isCompleted = true;
        _rotationController.stop();

        // Navigate to results screen after brief delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AnalysisResultsScreen(
                  analysisResult: update.result!,
                  originalImage: widget.selectedImage,
                ),
              ),
            );
          }
        });
      } else if (update.isTimeout) {
        _currentStatus = 'Analiz zaman aşımına uğradı';
        _currentError = update.exception as PlantAnalysisException?;
        _rotationController.stop();
      } else if (update.isError) {
        _currentStatus = 'Analiz başarısız';
        _currentError = update.exception as PlantAnalysisException?;
        _rotationController.stop();
      }
    });
  }

  void _handleError(dynamic error) {
    if (!mounted) return;

    setState(() {
      _currentStatus = 'Bağlantı hatası';
      _currentError = error is PlantAnalysisException
          ? error
          : NetworkException(
              'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
              originalError: error,
            );
      _rotationController.stop();
    });
  }

  void _navigateToDashboard() {
    // Navigate back to dashboard (remove all screens until dashboard)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _retryAnalysis() {
    setState(() {
      _currentError = null;
      _currentStatus = 'İşleniyor...';
      _isCompleted = false;
    });

    _rotationController.repeat();
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Processing Animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _isCompleted
                            ? const Color(0xFF22C55E).withOpacity(0.2)
                            : _currentError != null
                                ? const Color(0xFFEF4444).withOpacity(0.1)
                                : const Color(0xFF22C55E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Status icon
                    if (_isCompleted)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                    else if (_currentError != null)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 36,
                        ),
                      )
                    else
                      // Rotating processing icon
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * 3.14159,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sync,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          );
                        },
                      ),
                    // Queue number badge (only show when processing)
                    if (_currentQueuePosition != null && _currentError == null && !_isCompleted)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$_currentQueuePosition',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // Status Message
                Text(
                  _isCompleted
                      ? 'Analiz Tamamlandı!'
                      : _currentError != null
                          ? _currentStatus
                          : _currentQueuePosition != null
                              ? 'Sırada #$_currentQueuePosition'
                              : _currentStatus,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isCompleted
                        ? const Color(0xFF22C55E)
                        : _currentError != null
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Estimated time or error message
                if (_currentError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ErrorBannerWidget(
                      exception: _currentError!,
                    ),
                  )
                else if (widget.estimatedTime != null && !_isCompleted)
                  Text(
                    'Tahmini süre: ${widget.estimatedTime}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 32),

                // Analysis ID for reference
                Text(
                  'Analiz ID: ${widget.analysisId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                if (_currentError != null) ...[
                  // Retry button for errors (only if recoverable)
                  if (_currentError!.isRecoverable) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _retryAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ]

                else if (_isCompleted)
                  // Success message (will auto-navigate)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF22C55E),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sonuçlara yönlendiriliyorsunuz...',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!_isCompleted && _currentError == null)
                  // Notification message for processing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hazır olduğunda size bildirim göndereceğiz',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Back to Dashboard button
                TextButton(
                  onPressed: _navigateToDashboard,
                  child: const Text(
                    'Ana Sayfaya Dön',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}