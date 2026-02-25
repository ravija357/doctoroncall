import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../datasources/notification_local_data_source.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final result = await remoteDataSource.getNotifications();
      // Cache on success
      final notifications = result['notifications'] as List<NotificationModel>;
      final unreadCount = result['unreadCount'] as int;
      await localDataSource.cacheNotifications(notifications, unreadCount);
      return result;
    } catch (e) {
      // Fallback to cache
      final cached = localDataSource.getCachedNotifications();
      final notifications = cached['notifications'] as List<NotificationModel>;
      if (notifications.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    await remoteDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllAsRead() async {
    await remoteDataSource.markAllAsRead();
  }
}
