import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';
import '../pages/notifications_page.dart';

class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use GetIt to access NotificationBloc directly
    final notificationBloc = GetIt.instance<NotificationBloc>();

    return BlocBuilder<NotificationBloc, NotificationState>(
      bloc: notificationBloc,
      builder: (context, state) {
        print('🔔 NotificationBellIcon: Builder triggered!');
        print('🔔 NotificationBellIcon: Current state type: ${state.runtimeType}');

        final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;

        if (state is NotificationLoaded) {
          print('🔔 NotificationBellIcon: Loaded state - Unread count: $unreadCount, Total: ${state.notifications.length}');
        } else {
          print('🔔 NotificationBellIcon: State is NOT NotificationLoaded: $state');
        }

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            // Navigate to notification list screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
          tooltip: 'Bildirimler',
        );
      },
    );
  }
}