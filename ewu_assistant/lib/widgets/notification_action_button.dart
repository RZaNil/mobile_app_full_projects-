import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../screens/notifications_screen.dart';

class NotificationActionButton extends StatelessWidget {
  NotificationActionButton({
    super.key,
    this.backgroundColor = AppTheme.botBubble,
    this.foregroundColor = AppTheme.primaryDark,
  });

  final NotificationService _notificationService = NotificationService();
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final String uid = AuthService.currentUser?.uid ?? '';

    return StreamBuilder<int>(
      stream: _notificationService.watchUnreadCount(uid),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<NotificationsScreen>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -1,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 22),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
