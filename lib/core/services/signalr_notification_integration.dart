import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/dashboard/presentation/bloc/notification_bloc.dart';
import '../../features/dashboard/presentation/bloc/notification_event.dart';
import '../models/plant_analysis_notification.dart';
import '../models/message_notification.dart';
import '../models/dealer_invitation_notification.dart';
import 'signalr_service.dart';
import 'notification_signalr_service.dart';

/// Integration service that connects SignalR events with NotificationBloc
class SignalRNotificationIntegration {
  final SignalRService _signalRService;
  final NotificationSignalRService? _notificationHubService;
  final NotificationBloc _notificationBloc;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isInitialized = false;

  SignalRNotificationIntegration({
    required SignalRService signalRService,
    NotificationSignalRService? notificationHubService,
    required NotificationBloc notificationBloc,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _signalRService = signalRService,
        _notificationHubService = notificationHubService,
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

    // Handle new message notifications (ALL incoming messages)
    _signalRService.onNewMessage = (messageNotification) {
      print('💬 SignalRIntegration: CALLBACK TRIGGERED! New message from ${messageNotification.senderRole}');
      print('💬 SignalRIntegration: Message: ${messageNotification.message}');
      print('💬 SignalRIntegration: From user: ${messageNotification.fromUserName} (ID: ${messageNotification.fromUserId})');

      // ✅ CRITICAL: Show notifications for ALL incoming messages
      // - If sponsor sent → show to farmer
      // - If farmer sent → show to sponsor
      // Note: SignalR only sends to the OTHER party, not to the sender
      _showMessageNotification(messageNotification);

      // CRITICAL: Also add to NotificationBloc so it appears in notification bell icon
      // Convert MessageNotification to PlantAnalysisNotification format with full message details
      print('📲 SignalRIntegration: Adding message notification to bloc with full details...');

      final notificationTitle = messageNotification.isSponsorMessage
          ? 'Yeni Sponsor Mesajı'
          : 'Yeni Çiftçi Mesajı';

      final plantAnalysisNotification = PlantAnalysisNotification(
        analysisId: messageNotification.plantAnalysisId,
        userId: messageNotification.fromUserId,
        status: 'Message', // Custom status for message notifications
        completedAt: messageNotification.sentDate,
        primaryConcern: notificationTitle,
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
      print('✅ SignalRIntegration: Message notification added to bloc with sender: ${messageNotification.fromUserName} (${messageNotification.senderRole})!');
    };

    // Handle dealer invitation notifications
    _signalRService.addDealerInvitationListener((invitation) {
      print('🎉 SignalRIntegration: CALLBACK TRIGGERED! New dealer invitation from ${invitation.sponsorCompanyName}');
      print('🎉 SignalRIntegration: Invitation data: ${invitation.codeCount} codes, tier: ${invitation.packageTier}');

      // Show local notification for dealer invitation
      _showDealerInvitationNotification(invitation);

      // Add to NotificationBloc so it appears in notification bell icon
      final plantAnalysisNotification = PlantAnalysisNotification(
        analysisId: invitation.invitationId,
        userId: invitation.invitationId,
        status: 'DealerInvitation',
        completedAt: invitation.createdAt,
        primaryConcern: 'Yeni Bayi Davetiyesi',
        message: '${invitation.sponsorCompanyName} tarafından ${invitation.codeCount} kod davetiyesi gönderildi',
        sponsorId: invitation.invitationId.toString(),
        isRead: false,
        deepLink: 'dealer_invitation_${invitation.token}',
      );

      _notificationBloc.add(AddNotification(plantAnalysisNotification));
      print('✅ SignalRIntegration: Dealer invitation notification added to bloc!');
    });

    // ✅ Setup NotificationHub dealer invitation handler (if available)
    if (_notificationHubService != null) {
      print('🔔 SignalRIntegration: Setting up NotificationHub dealer invitation handler...');
      _notificationHubService!.addDealerInvitationListener((invitation) {
        print('🎉 SignalRIntegration: CALLBACK TRIGGERED! New dealer invitation from ${invitation.sponsorCompanyName}');
        print('🎉 SignalRIntegration: ${invitation.codeCount} codes, expires in ${invitation.remainingDays} days');

        // Show local notification
        print('🔔 SignalRIntegration: Showing notification for dealer invitation');
        _showDealerInvitationNotification(invitation);

        // Add to NotificationBloc
        print('📲 SignalRIntegration: Adding dealer invitation to notification bloc...');
        final plantAnalysisNotification = PlantAnalysisNotification(
          analysisId: invitation.invitationId,
          userId: 0,
          status: 'DealerInvitation',
          completedAt: invitation.createdAt,
          message: '${invitation.sponsorCompanyName} sizi bayiliğe davet ediyor',
          primaryConcern: '${invitation.codeCount} kod, ${invitation.remainingDays} gün geçerli',
        );

        _notificationBloc.add(AddNotification(plantAnalysisNotification));
        print('✅ SignalRIntegration: Dealer invitation notification added to bloc!');
      });
      print('✅ SignalRIntegration: NotificationHub handler setup complete!');
    } else {
      print('⚠️ SignalRIntegration: NotificationHub service not provided - dealer invitations disabled');
    }

    _isInitialized = true;
    print('✅ SignalRIntegration: Event handlers setup complete!');
  }

  /// Show local notification for incoming message (sponsor or farmer)
  void _showMessageNotification(MessageNotification messageNotification) {
    if (_localNotifications == null) {
      print('⚠️ SignalRIntegration: Local notifications not initialized');
      return;
    }

    print('🔔 SignalRIntegration: Showing notification for message from ${messageNotification.fromUserCompany ?? messageNotification.fromUserName}');

    // ✅ Different channels for sponsor vs farmer messages
    final channelId = messageNotification.isSponsorMessage ? 'sponsor_messages' : 'farmer_messages';
    final channelName = messageNotification.isSponsorMessage ? 'Sponsor Mesajları' : 'Çiftçi Mesajları';
    final channelDescription = messageNotification.isSponsorMessage
        ? 'Sponsorlardan gelen mesaj bildirimleri'
        : 'Çiftçilerden gelen mesaj bildirimleri';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
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

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ✅ Enhanced title and body with sender info and analysis ID
    final senderName = messageNotification.fromUserCompany ?? messageNotification.fromUserName ?? 'Kullanıcı';
    final title = messageNotification.isSponsorMessage
        ? 'Yeni Sponsor Mesajı'
        : 'Yeni Çiftçi Mesajı';
    final body = '$senderName (Analiz #${messageNotification.plantAnalysisId}): ${messageNotification.message}';

    _localNotifications!.show(
      messageNotification.messageId,
      title,
      body,
      notificationDetails,
      payload: 'message_${messageNotification.plantAnalysisId}',
    );

    print('✅ SignalRIntegration: Notification shown successfully');
  }

  /// Show local notification for dealer invitation
  void _showDealerInvitationNotification(DealerInvitationNotification invitation) {
    if (_localNotifications == null) {
      print('⚠️ SignalRIntegration: Local notifications not initialized');
      return;
    }

    print('🔔 SignalRIntegration: Showing notification for dealer invitation from ${invitation.sponsorCompanyName}');

    const androidDetails = AndroidNotificationDetails(
      'dealer_invitations',
      'Bayi Davetiyeleri',
      channelDescription: 'Sponsorlardan gelen bayi davetiye bildirimleri',
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

    final title = 'Yeni Bayi Davetiyesi';
    final body = '${invitation.sponsorCompanyName} tarafından ${invitation.codeCount} kod davetiyesi gönderildi. ${invitation.expirationMessage}';

    _localNotifications!.show(
      invitation.invitationId,
      title,
      body,
      notificationDetails,
      payload: 'dealer_invitation_${invitation.token}',
    );

    print('✅ SignalRIntegration: Dealer invitation notification shown successfully');
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