import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/models/plant_analysis_notification.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../../plant_analysis/presentation/screens/analysis_detail_screen.dart';
import '../../../messaging/presentation/pages/chat_conversation_page.dart'; // ✅ NEW: For message notifications

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationBloc = GetIt.instance<NotificationBloc>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            bloc: notificationBloc,
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    notificationBloc.add(const MarkAllNotificationsAsRead());
                  },
                  child: const Text('Tümünü Okundu İşaretle'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Tüm Bildirimleri Temizle'),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        bloc: notificationBloc,
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                  onDismiss: () {
                    context.read<NotificationBloc>().add(
                          ClearNotification(notification.analysisId),
                        );
                  },
                );
              },
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bildirim yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bitki analizi tamamlandığında buradan bildirim alacaksınız',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    PlantAnalysisNotification notification,
  ) {
    final notificationBloc = GetIt.instance<NotificationBloc>();

    // Mark as read
    if (!notification.isRead) {
      notificationBloc.add(MarkNotificationAsRead(notification.analysisId));
    }

    // ✅ SMART NAVIGATION: Route based on notification type
    if (notification.isMessageNotification) {
      // Message notification → Navigate to chat page
      print('📱 Navigating to chat for message notification from ${notification.senderDisplayName}');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatConversationPage(
            plantAnalysisId: notification.analysisId,
            farmerId: notification.userId, // Current user is farmer
            sponsorUserId: int.parse(notification.sponsorId ?? '0'), // Sender is sponsor
            sponsorshipTier: 'L', // Default tier, will be loaded from API
          ),
        ),
      );
    } else {
      // Analysis notification → Navigate to analysis detail
      print('📊 Navigating to analysis detail for notification ${notification.analysisId}');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AnalysisDetailScreen(analysisId: notification.analysisId),
        ),
      );
    }
  }

  void _showClearAllDialog(BuildContext context) {
    final notificationBloc = GetIt.instance<NotificationBloc>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tüm Bildirimleri Temizle'),
        content: const Text(
          'Tüm bildirimleri silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              notificationBloc.add(const ClearAllNotifications());
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Temizle',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final PlantAnalysisNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final notificationBloc = GetIt.instance<NotificationBloc>();
    
    return Dismissible(
      key: Key('notification_${notification.analysisId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead
            ? Colors.grey.shade100
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead
                ? Colors.grey.shade300
                : Theme.of(context).primaryColor.withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ ENHANCED: Different icons for message vs analysis notifications
                _buildNotificationIcon(context, notification),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.displayTitle, // ✅ Use helper method
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: notification.isRead
                                    ? Colors.grey.shade700
                                    : Colors.black,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ✅ ENHANCED: Show sender name for messages, crop type for analysis
                      if (notification.isMessageNotification && notification.senderDisplayName != null)
                        Text(
                          notification.senderDisplayName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (notification.cropType != null)
                        Text(
                          notification.cropType!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      // ✅ ENHANCED: Show message content or primary concern
                      if (notification.message != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            notification.message!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else if (notification.primaryConcern != null)
                        Text(
                          notification.primaryConcern!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (notification.overallHealthScore != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              size: 16,
                              color: _getHealthScoreColor(
                                notification.overallHealthScore!,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sağlık Skoru: ${notification.overallHealthScore}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getHealthScoreColor(
                                  notification.overallHealthScore!,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.completedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ NEW: Build notification icon based on type
  Widget _buildNotificationIcon(BuildContext context, PlantAnalysisNotification notification) {
    if (notification.isMessageNotification) {
      // Message notification - Show avatar or message icon
      if (notification.senderAvatarUrl != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Image.network(
            notification.senderAvatarUrl!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildMessageIconFallback(context);
            },
          ),
        );
      }
      return _buildMessageIconFallback(context);
    }

    // Analysis notification - Show image or plant icon
    if (notification.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          notification.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlantIconFallback(context);
          },
        ),
      );
    }
    return _buildPlantIconFallback(context);
  }

  Widget _buildMessageIconFallback(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.message_rounded,
        color: Colors.blue.shade700,
        size: 30,
      ),
    );
  }

  Widget _buildPlantIconFallback(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.eco,
        color: Theme.of(context).primaryColor,
        size: 30,
      ),
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(dateTime);
    }
  }
}