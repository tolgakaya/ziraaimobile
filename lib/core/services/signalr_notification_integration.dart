import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/dashboard/presentation/bloc/notification_bloc.dart';
import '../../features/dashboard/presentation/bloc/notification_event.dart';
import '../models/plant_analysis_notification.dart';
import 'signalr_service.dart';

/// Integration service that connects SignalR events with NotificationBloc
class SignalRNotificationIntegration {
  final SignalRService _signalRService;
  final NotificationBloc _notificationBloc;
  bool _isInitialized = false;

  SignalRNotificationIntegration({
    required SignalRService signalRService,
    required NotificationBloc notificationBloc,
  })  : _signalRService = signalRService,
        _notificationBloc = notificationBloc;

  /// Setup SignalR event handlers to update NotificationBloc
  void setupEventHandlers() {
    if (_isInitialized) {
      developer.log('SignalR event handlers already initialized', name: 'SignalRIntegration');
      return;
    }

    // Handle analysis completed notifications
    _signalRService.onAnalysisCompleted = (notification) {
      developer.log(
        '📨 Received analysis completed: ${notification.analysisId}',
        name: 'SignalRIntegration',
      );

      // Add notification to bloc
      _notificationBloc.add(AddNotification(notification));
    };

    // Handle analysis failed notifications
    _signalRService.onAnalysisFailed = (analysisId, errorMessage) {
      developer.log(
        '❌ Received analysis failed: $analysisId - $errorMessage',
        name: 'SignalRIntegration',
      );

      // Create a failed notification
      final notification = PlantAnalysisNotification(
        analysisId: analysisId,
        userId: 0, // Will be set by backend in real scenario
        status: 'Failed',
        completedAt: DateTime.now(),
        message: errorMessage,
        primaryConcern: 'Analiz başarısız oldu',
      );

      _notificationBloc.add(AddNotification(notification));
    };

    _isInitialized = true;
    developer.log('SignalR event handlers setup complete', name: 'SignalRIntegration');
  }

  /// Clear event handlers
  void clearEventHandlers() {
    _signalRService.clearHandlers();
    _isInitialized = false;
    developer.log('SignalR event handlers cleared', name: 'SignalRIntegration');
  }

  /// Check if handlers are initialized
  bool get isInitialized => _isInitialized;
}