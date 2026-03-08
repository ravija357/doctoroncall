import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';
import 'package:doctoroncall/features/messages/data/models/message_model.dart';
import '../../../../helpers/test_helpers.mocks.dart';

// Depending on your project's mock generation setup,
// you might need to adjust the import path to MockApiClient and MockDio.
void main() {
  late ChatRemoteDataSourceImpl dataSource;
  late MockApiClient mockApiClient;
  late MockDio mockDio;

  setUp(() {
    mockApiClient = MockApiClient();
    mockDio = MockDio();
    when(mockApiClient.dio).thenReturn(mockDio);

    dataSource = ChatRemoteDataSourceImpl(apiClient: mockApiClient);
  });

  group('ChatRemoteDataSourceImpl Tests', () {
    final tContactsJson = {
      'success': true,
      'data': [
        {'id': 'contact1', 'name': 'Dr. Mock', 'role': 'doctor', 'unread': 0},
      ],
    };

    final tMessagesJson = {
      'success': true,
      'data': [
        {
          '_id': 'msg1',
          'content': 'Hello from mock',
          'type': 'text',
          'sender': 'pat1',
          'receiver': 'doc1',
          'createdAt': '2023-01-01T12:00:00.000Z',
        },
      ],
    };

    test('getContacts should return list of ChatContact on success', () async {
      when(mockDio.get('/messages/contacts')).thenAnswer(
        (_) async => Response(
          data: tContactsJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/messages/contacts'),
        ),
      );

      final result = await dataSource.getContacts();

      expect(result, isA<List<ChatContact>>());
      expect(result.length, 1);
      expect(result.first.id, 'contact1');
      verify(mockDio.get('/messages/contacts'));
    });

    test('getContacts should throw ServerException on failure', () async {
      when(mockDio.get('/messages/contacts')).thenAnswer(
        (_) async => Response(
          data: {'success': false},
          statusCode: 400,
          requestOptions: RequestOptions(path: '/messages/contacts'),
        ),
      );

      expect(() => dataSource.getContacts(), throwsA(isA<ServerException>()));
    });

    test('getMessages should return list of MessageModel on success', () async {
      when(mockDio.get('/messages/doc1')).thenAnswer(
        (_) async => Response(
          data: tMessagesJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/messages/doc1'),
        ),
      );

      final result = await dataSource.getMessages('doc1');

      expect(result, isA<List<MessageModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'msg1');
      verify(mockDio.get('/messages/doc1'));
    });

    test('getMessages should throw ServerException on Dio error', () async {
      when(mockDio.get('/messages/doc1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/messages/doc1'),
          response: Response(
            data: {'message': 'Not Found'},
            statusCode: 404,
            requestOptions: RequestOptions(path: '/messages/doc1'),
          ),
        ),
      );

      expect(
        () => dataSource.getMessages('doc1'),
        throwsA(isA<ServerException>()),
      );
    });

    test('markAsRead should complete successfully on 200 OK', () async {
      when(mockDio.put('/messages/read/doc1')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/messages/read/doc1'),
        ),
      );

      await dataSource.markAsRead('doc1');
      verify(mockDio.put('/messages/read/doc1')).called(1);
    });
  });
}
