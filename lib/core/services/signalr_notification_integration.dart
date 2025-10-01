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
    print('🔗 SignalRIntegration: Setting up event handlers...');
    if (_isInitialized) {
      print('⚠️ SignalRIntegration: Event handlers already initialized');
      return;
    }

    // Handle analysis completed notifications
    _signalRService.onAnalysisCompleted = (notification) {
      print('🎉🎉🎉 SignalRIntegration: CALLBACK TRIGGERED! Analysis completed: ${notification.analysisId}');
      print('🎉 SignalRIntegration: Notification data: $notification');

      // Add notification to bloc
      print('🎉 SignalRIntegration: Adding notification to bloc...');
      _notificationBloc.add(AddNotification(notification));
      print('🎉 SignalRIntegration: Notification added to bloc successfully!');
    };

    // Handle analysis failed notifications
    _signalRService.onAnalysisFailed = (analysisId, errorMessage) {
      print('❌ SignalRIntegration: CALLBACK TRIGGERED! Analysis failed: $analysisId - $errorMessage');

      // Create a failed notification
      final notification = PlantAnalysisNotification(
        analysisId: analysisId,
        userId: 0, // Will be set by backend in real scenario
        status: 'Failed',
        completedAt: DateTime.now(),
        message: errorMessage,
        primaryConcern: 'Analiz başarısız oldu',
      );

      print('❌ SignalRIntegration: Adding failed notification to bloc...');
      _notificationBloc.add(AddNotification(notification));
    };

    _isInitialized = true;
    print('✅ SignalRIntegration: Event handlers setup complete!');
  }

  /// Clear event handlers
  void clearEventHandlers() {
    _signalRService.clearHandlers();
    _isInitialized = false;
    print('🔌 SignalRIntegration: Event handlers cleared');
  }

  /// Check if handlers are initialized
  bool get isInitialized => _isInitialized;
}