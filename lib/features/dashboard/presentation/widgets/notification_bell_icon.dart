import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_state.dart';

class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to access NotificationBloc, if not available show icon without badge
    try {
      return BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          final unreadCount = state is NotificationLoaded ? state.unreadCount : 0;

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
            context.push('/notifications');
          },
          tooltip: 'Bildirimler',
        );
      },
    );
    } catch (e) {
      // Fallback: Show icon without badge if provider not available
      return IconButton(
        icon: const Icon(
          Icons.notifications_outlined,
          color: Colors.grey,
          size: 28,
        ),
        onPressed: () {
          // Navigate to notification list screen
          context.push('/notifications');
        },
        tooltip: 'Bildirimler',
      );
    }
  }
}