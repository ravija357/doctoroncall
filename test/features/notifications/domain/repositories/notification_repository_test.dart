import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationRemoteDataSource mockRemoteDataSource;
  late MockNotificationLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockNotificationRemoteDataSource();
    mockLocalDataSource = MockNotificationLocalDataSource();
    repository = NotificationRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('NotificationRepositoryImpl', () {
    final tNotificationModel = NotificationModel(
      id: '1',
      message: 'Message',
      type: 'INFO',
      isRead: false,
      createdAt: DateTime.now(),
    );
    final tNotificationsMap = {
      'notifications': [tNotificationModel],
      'unreadCount': 1,
    };

    test('should return notifications and cache them on success', () async {
      // arrange
      when(
        mockRemoteDataSource.getNotifications(),
      ).thenAnswer((_) async => tNotificationsMap);
      when(
        mockLocalDataSource.cacheNotifications(any, any),
      ).thenAnswer((_) async => Future.value());

      // act
      final result = await repository.getNotifications();

      // assert
      expect(result, equals(tNotificationsMap));
      verify(mockRemoteDataSource.getNotifications());
      verify(
        mockLocalDataSource.cacheNotifications(
          tNotificationsMap['notifications'] as List<NotificationModel>,
          1,
        ),
      );
    });

    test('should mark notification as read using remote data source', () async {
      // arrange
      when(
        mockRemoteDataSource.markAsRead('1'),
      ).thenAnswer((_) async => Future.value());

      // act
      await repository.markAsRead('1');

      // assert
      verify(mockRemoteDataSource.markAsRead('1'));
    });
  });
}
