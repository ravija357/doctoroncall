import '../entities/notification.dart' as entity;

abstract class NotificationRepository {
  Future<Map<String, dynamic>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}
