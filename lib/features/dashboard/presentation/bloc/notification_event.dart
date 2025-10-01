import 'package:equatable/equatable.dart';
import '../../../../core/models/plant_analysis_notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

class AddNotification extends NotificationEvent {
  final PlantAnalysisNotification notification;

  const AddNotification(this.notification);

  @override
  List<Object?> get props => [notification];
}

class MarkNotificationAsRead extends NotificationEvent {
  final int analysisId;

  const MarkNotificationAsRead(this.analysisId);

  @override
  List<Object?> get props => [analysisId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

class ClearNotification extends NotificationEvent {
  final int analysisId;

  const ClearNotification(this.analysisId);

  @override
  List<Object?> get props => [analysisId];
}

class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}