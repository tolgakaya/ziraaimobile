import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/dashboard/presentation/bloc/notification_bloc.dart';
import '../../features/dashboard/presentation/bloc/notification_event.dart';
import '../models/plant_analysis_notification.dart';
import '../models/message_notification.dart';
import 'signalr_service.dart';

/// Integration service that connects SignalR events with NotificationBloc
class SignalRNotificationIntegration {
  final SignalRService _signalRService;
  final NotificationBloc _notificationBloc;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isInitialized = false;

  SignalRNotificationIntegration({
    required SignalRService signalRService,
    required NotificationBloc notificationBloc,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _signalRService = signalRService,
        _notificationBloc = notificationBloc,
        _localNotifications = localNotifications;

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

    // Handle new message notifications (sponsor→farmer only)
    _signalRService.onNewMessage = (messageNotification) {
      print('💬 SignalRIntegration: CALLBACK TRIGGERED! New message from ${messageNotification.senderRole}');
      print('💬 SignalRIntegration: Message: ${messageNotification.message}');

      // Show local notification for sponsor→farmer messages
      if (messageNotification.isSponsorMessage) {
        _showMessageNotification(messageNotification);

        // CRITICAL: Also add to NotificationBloc so it appears in notification bell icon
        // Convert MessageNotification to PlantAnalysisNotification format with full message details
        print('📲 SignalRIntegration: Adding message notification to bloc with full details...');
        final plantAnalysisNotification = PlantAnalysisNotification(
          analysisId: messageNotification.plantAnalysisId,
          userId: messageNotification.fromUserId,
          status: 'Message', // Custom status for message notifications
          completedAt: messageNotification.sentDate,
          primaryConcern: 'Yeni Sponsor Mesajı',
          message: messageNotification.message,
          sponsorId: messageNotification.fromUserId.toString(),
          isRead: false,
          // ✅ NEW: Pass message-specific details
          messageId: messageNotification.messageId,
          fromUserName: messageNotification.fromUserName,
          fromUserCompany: messageNotification.fromUserCompany,
          senderAvatarUrl: messageNotification.senderAvatarUrl,
          senderRole: messageNotification.senderRole,
        );

        _notificationBloc.add(AddNotification(plantAnalysisNotification));
        print('✅ SignalRIntegration: Message notification added to bloc with sender: ${messageNotification.fromUserName}!');
      }
    };

    _isInitialized = true;
    print('✅ SignalRIntegration: Event handlers setup complete!');
  }

  /// Show local notification for incoming sponsor message
  void _showMessageNotification(MessageNotification messageNotification) {
    if (_localNotifications == null) {
      print('⚠️ SignalRIntegration: Local notifications not initialized');
      return;
    }

    print('🔔 SignalRIntegration: Showing notification for message from ${messageNotification.fromUserCompany ?? messageNotification.fromUserName}');

    const androidDetails = AndroidNotificationDetails(
      'sponsor_messages',
      'Sponsor Mesajları',
      channelDescription: 'Sponsorlardan gelen mesaj bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = messageNotification.fromUserCompany ?? messageNotification.fromUserName;
    final body = messageNotification.message;

    _localNotifications!.show(
      messageNotification.messageId,
      '💬 $title',
      body,
      notificationDetails,
      payload: 'message_${messageNotification.plantAnalysisId}',
    );

    print('✅ SignalRIntegration: Notification shown successfully');
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