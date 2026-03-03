import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/notifications/presentation/providers/notification_provider.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationNotifierProvider.notifier).loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationNotifierProvider.notifier).markAllAsRead();
            },
            child: Text('Mark all as read', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(notificationNotifierProvider);
          if (state is NotificationLoading) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          } else if (state is NotificationError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is NotificationsLoaded) {
            final notifications = state.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_outlined, size: 64, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet.',
                      style: TextStyle(fontSize: 18, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final bgColor = n.isRead 
                    ? theme.cardColor 
                    : theme.primaryColor.withOpacity(isDark ? 0.12 : 0.05);
                final borderColor = n.isRead 
                    ? (isDark ? theme.dividerColor.withOpacity(0.05) : Colors.grey.shade100)
                    : theme.primaryColor.withOpacity(0.2);

                return GestureDetector(
                  onTap: () {
                    if (!n.isRead) {
                      ref.read(notificationNotifierProvider.notifier).markAsRead(n.id);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: isDark ? [] : [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getTypeColor(n.type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getTypeIcon(n.type), color: _getTypeColor(n.type), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.message,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                  fontSize: 15,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM d, h:mm a').format(n.createdAt),
                                style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 4),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SUCCESS': return Colors.green;
      case 'WARNING': return Colors.orange;
      case 'ERROR': return Colors.red;
      default: return const Color(0xFF6AA9D8);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SUCCESS': return Icons.check_circle_outline;
      case 'WARNING': return Icons.warning_amber_rounded;
      case 'ERROR': return Icons.error_outline;
      default: return Icons.notifications_outlined;
    }
  }
}
