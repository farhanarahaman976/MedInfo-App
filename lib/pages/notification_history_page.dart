import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_history_service.dart';
import '../services/order_service.dart';
import 'order_details_page.dart';
import 'reminder_page.dart';

class NotificationHistoryPage extends StatelessWidget {
  final String userId;

  const NotificationHistoryPage({super.key, required this.userId});

  static const Color _primary = Color(0xFF3B82C4);

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.order:
        return Icons.receipt_long_rounded;
      case AppNotificationType.orderStatus:
        return Icons.local_shipping_rounded;
      case AppNotificationType.reminder:
        return Icons.alarm_rounded;
      case AppNotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.order:
        return _primary;
      case AppNotificationType.orderStatus:
        return const Color(0xFF0F6E56);
      case AppNotificationType.reminder:
        return const Color(0xFFBA7517);
      case AppNotificationType.general:
        return Colors.grey;
    }
  }

  Future<void> _handleTap(BuildContext context, AppNotification n) async {
    // Read mark kore, tarpor relevant page e navigate kore
    await NotificationHistoryService().markAsRead(n.id);
    if (!context.mounted) return;

    if ((n.type == AppNotificationType.order ||
            n.type == AppNotificationType.orderStatus) &&
        n.referenceId != null) {
      final order = await OrderService().getOrderById(n.referenceId!);
      if (order != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsPage(order: order)),
        );
      }
    } else if (n.type == AppNotificationType.reminder) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReminderPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () => NotificationHistoryService().markAllAsRead(userId),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationHistoryService().getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'There is a problem loading the notification.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No notifications to show',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: n.isRead
                      ? (isDark ? const Color(0xFF1C1E26) : Colors.white)
                      : (isDark
                          ? _primary.withValues(alpha: 0.08)
                          : _primary.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _handleTap(context, n),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _colorFor(n.type).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconFor(n.type),
                              size: 20,
                              color: _colorFor(n.type),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: n.isRead
                                              ? FontWeight.w600
                                              : FontWeight.w800,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F1117),
                                        ),
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE24B4A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _relativeTime(n.createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
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
            },
          );
        },
      ),
    );
  }
}