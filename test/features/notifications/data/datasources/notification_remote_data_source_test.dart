import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:doctoroncall/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late NotificationRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(mockApiClient.dio).thenReturn(mockDio);

    dataSource = NotificationRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('NotificationRemoteDataSourceImpl Tests', () {
    final tNotificationsJson = {
      'data': [
        {
          '_id': 'note1',
          'message': 'Test Notification',
          'type': 'INFO',
          'createdAt': '2023-01-01T12:00:00.000Z',
        },
      ],
      'unreadCount': 1,
    };

    test('getNotifications should return map on success', () async {
      when(mockDio.get('/notifications')).thenAnswer(
        (_) async => Response(
          data: tNotificationsJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/notifications'),
        ),
      );

      final result = await dataSource.getNotifications();

      expect(result['unreadCount'], 1);
      expect(result['notifications'], isA<List<NotificationModel>>());
      final List<NotificationModel> list = result['notifications'];
      expect(list.length, 1);
      expect(list.first.id, 'note1');
      verify(mockDio.get('/notifications'));
    });

    test('getNotifications should throw ServerException on failure', () async {
      when(mockDio.get('/notifications')).thenAnswer(
        (_) async => Response(
          data: {'message': 'Error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/notifications'),
        ),
      );

      expect(
        () => dataSource.getNotifications(),
        throwsA(isA<ServerException>()),
      );
    });

    test('markAsRead should complete successfully on 200 OK', () async {
      when(mockDio.put('/notifications/note1/read')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/notifications/note1/read'),
        ),
      );

      await dataSource.markAsRead('note1');
      verify(mockDio.put('/notifications/note1/read')).called(1);
    });

    test('markAllAsRead should complete successfully on 200 OK', () async {
      when(mockDio.put('/notifications/read-all')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/notifications/read-all'),
        ),
      );

      await dataSource.markAllAsRead();
      verify(mockDio.put('/notifications/read-all')).called(1);
    });
  });
}
