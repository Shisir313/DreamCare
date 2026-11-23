import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _notifications = [
    const _NotificationItem(
      icon: Icons.calendar_today,
      title: 'Appointment reminder',
      body: 'Your video consultation is in 2 days.',
      time: '10 min ago',
      unread: true,
    ),
    const _NotificationItem(
      icon: Icons.water_drop_outlined,
      title: 'Hydration reminder',
      body: 'Time to drink a glass of water.',
      time: '1 hour ago',
      unread: true,
    ),
    const _NotificationItem(
      icon: Icons.medication_outlined,
      title: 'Prescription update',
      body: 'Your dermatologist added new care notes.',
      time: 'Yesterday',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var index = 0; index < _notifications.length; index++) {
                  final item = _notifications[index];
                  _notifications[index] = _NotificationItem(
                    icon: item.icon,
                    title: item.title,
                    body: item.body,
                    time: item.time,
                    unread: false,
                  );
                }
              });
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            leading: CircleAvatar(
              backgroundColor: notification.unread
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(notification.icon),
            ),
            title: Text(
              notification.title,
              style: notification.unread
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : theme.textTheme.titleSmall,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text('${notification.body}\n${notification.time}'),
            ),
            onTap: () {
              setState(() {
                final item = _notifications[index];
                _notifications[index] = _NotificationItem(
                  icon: item.icon,
                  title: item.title,
                  body: item.body,
                  time: item.time,
                  unread: false,
                );
              });
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool unread;
}
