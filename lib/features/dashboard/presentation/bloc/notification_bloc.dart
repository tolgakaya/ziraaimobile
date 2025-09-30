import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../../core/models/plant_analysis_notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final List<PlantAnalysisNotification> _notifications = [];

  NotificationBloc() : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<AddNotification>(_onAddNotification);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<ClearNotification>(_onClearNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());

    try {
      // Sort by completion date, newest first
      _notifications.sort((a, b) => b.completedAt.compareTo(a.completedAt));

      final unreadCount = _notifications.where((n) => !n.isRead).length;

      developer.log(
        'Loaded ${_notifications.length} notifications, $unreadCount unread',
        name: 'NotificationBloc',
      );

      emit(NotificationLoaded(
        notifications: List.from(_notifications),
        unreadCount: unreadCount,
      ));
    } catch (e) {
      developer.log(
        'Error loading notifications: $e',
        name: 'NotificationBloc',
        error: e,
      );
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onAddNotification(
    AddNotification event,
    Emitter<NotificationState> emit,
  ) async {
    // Check if notification already exists
    final existingIndex = _notifications.indexWhere(
      (n) => n.analysisId == event.notification.analysisId,
    );

    if (existingIndex >= 0) {
      // Update existing notification
      _notifications[existingIndex] = event.notification;
      developer.log(
        'Updated existing notification for analysis ${event.notification.analysisId}',
        name: 'NotificationBloc',
      );
    } else {
      // Add new notification
      _notifications.insert(0, event.notification);
      developer.log(
        'Added new notification for analysis ${event.notification.analysisId}',
        name: 'NotificationBloc',
      );
    }

    // Sort by completion date, newest first
    _notifications.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    emit(NotificationLoaded(
      notifications: List.from(_notifications),
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final index = _notifications.indexWhere(
      (n) => n.analysisId == event.analysisId,
    );

    if (index >= 0 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);

      final unreadCount = _notifications.where((n) => !n.isRead).length;

      developer.log(
        'Marked notification ${event.analysisId} as read',
        name: 'NotificationBloc',
      );

      emit(NotificationLoaded(
        notifications: List.from(_notifications),
        unreadCount: unreadCount,
      ));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }

    developer.log(
      'Marked all notifications as read',
      name: 'NotificationBloc',
    );

    emit(NotificationLoaded(
      notifications: List.from(_notifications),
      unreadCount: 0,
    ));
  }

  Future<void> _onClearNotification(
    ClearNotification event,
    Emitter<NotificationState> emit,
  ) async {
    _notifications.removeWhere((n) => n.analysisId == event.analysisId);

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    developer.log(
      'Cleared notification ${event.analysisId}',
      name: 'NotificationBloc',
    );

    emit(NotificationLoaded(
      notifications: List.from(_notifications),
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    _notifications.clear();

    developer.log(
      'Cleared all notifications',
      name: 'NotificationBloc',
    );

    emit(NotificationLoaded(
      notifications: [],
      unreadCount: 0,
    ));
  }
}