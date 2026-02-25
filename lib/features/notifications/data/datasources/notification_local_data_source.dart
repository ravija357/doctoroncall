import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model.dart';

class NotificationLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.notifications);

  /// Get cached notifications
  Map<String, dynamic> getCachedNotifications() {
    final raw = _box.get('notifications_list');
    if (raw == null) return {'notifications': <NotificationModel>[], 'unreadCount': 0};
    final List<dynamic> list = raw;
    final notifications = list
        .map((e) => NotificationModel.fromHiveMap(Map<dynamic, dynamic>.from(e)))
        .toList();
    final unreadCount = _box.get('unread_count', defaultValue: 0);
    return {
      'notifications': notifications,
      'unreadCount': unreadCount,
    };
  }

  /// Cache notifications
  Future<void> cacheNotifications(List<NotificationModel> notifications, int unreadCount) async {
    await _box.put(
      'notifications_list',
      notifications.map((n) => n.toHiveMap()).toList(),
    );
    await _box.put('unread_count', unreadCount);
  }

  /// Clear all cached notifications
  Future<void> clearCache() async {
    await _box.clear();
  }
}
