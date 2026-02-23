import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../../../../core/error/server_exception.dart';

abstract class NotificationRemoteDataSource {
  Future<Map<String, dynamic>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await apiClient.dio.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data['data'];
        final notifications = list.map((e) => NotificationModel.fromJson(e)).toList();
        final unreadCount = response.data['unreadCount'] ?? 0;
        return {
          'notifications': notifications,
          'unreadCount': unreadCount,
        };
      } else {
        throw ServerException(message: 'Failed to fetch notifications');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Error fetching notifications');
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      final response = await apiClient.dio.put('/notifications/$id/read');
      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to mark notification as read');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Error marking notification read');
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await apiClient.dio.put('/notifications/read-all');
      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to mark all notifications as read');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Error marking all notifications read');
    }
  }
}
