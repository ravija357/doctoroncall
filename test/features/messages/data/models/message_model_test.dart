import 'package:flutter_test/flutter_test.dart';
import 'package:doctoroncall/features/messages/data/models/message_model.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tMessageModel = MessageModel(
    id: 'msg1',
    senderId: 'user1',
    receiverId: 'user2',
    content: 'Hello World',
    timestamp: tDate,
    isRead: false,
    type: 'text',
    fileUrl: null,
    fileName: null,
  );

  group('MessageModel Tests', () {
    test('should be a subclass of Message entity', () async {
      // assert
      expect(tMessageModel, isA<Message>());
    });

    test('fromJson should return a valid model from full string IDs', () async {
      // arrange
      final Map<String, dynamic> jsonMap = {
        '_id': 'msg1',
        'sender': 'user1',
        'receiver': 'user2',
        'content': 'Hello World',
        'createdAt': tDate.toIso8601String(),
        'read': false,
        'type': 'text',
      };

      // act
      final result = MessageModel.fromJson(jsonMap);

      // assert
      expect(result.id, 'msg1');
      expect(result.senderId, 'user1');
      expect(result.receiverId, 'user2');
      expect(result.content, 'Hello World');
      expect(result.isRead, false);
      expect(result.type, 'text');
    });

    test(
      'fromJson should return a valid model with Map objects as sender/receiver due to Mongoose populate',
      () async {
        final Map<String, dynamic> jsonMap = {
          '_id': 'msg2',
          'sender': {'_id': 'user1', 'name': 'John'},
          'receiver': {'_id': 'user2', 'name': 'Doe'},
          'content': 'Hello Map',
          'timestamp': tDate.toIso8601String(),
          'read': true,
          'type': 'image',
          'fileUrl': 'http://image.url',
          'fileName': 'image.png',
        };

        final result = MessageModel.fromJson(jsonMap);

        expect(result.id, 'msg2');
        expect(result.senderId, 'user1');
        expect(result.receiverId, 'user2');
        expect(result.content, 'Hello Map');
        expect(result.isRead, true);
        expect(result.type, 'image');
        expect(result.fileUrl, 'http://image.url');
        expect(result.fileName, 'image.png');
      },
    );

    test('fromJson should handle null fields and provide defaults', () async {
      final Map<String, dynamic> jsonMap = {'sender': null, 'receiver': null};

      final result = MessageModel.fromJson(jsonMap);

      expect(result.id, null);
      expect(result.senderId, '');
      expect(result.receiverId, '');
      expect(result.content, '');
      expect(result.isRead, false);
      expect(result.type, 'text');
    });

    test('toJson should return a JSON map containing proper data', () async {
      // act
      final result = tMessageModel.toJson();

      // assert
      final expectedMap = {
        'senderId': 'user1',
        'receiverId': 'user2',
        'content': 'Hello World',
        'type': 'text',
        'timestamp': tDate.toIso8601String(),
        'isRead': false,
      };
      expect(result, expectedMap);
    });

    test('toJson should include file fields if they are not null', () async {
      final modelWithFile = MessageModel(
        senderId: 'user1',
        receiverId: 'user2',
        content: '',
        timestamp: tDate,
        type: 'file',
        fileUrl: 'url',
        fileName: 'name.pdf',
      );

      final result = modelWithFile.toJson();

      expect(result.containsKey('fileUrl'), true);
      expect(result['fileUrl'], 'url');
      expect(result.containsKey('fileName'), true);
      expect(result['fileName'], 'name.pdf');
    });
  });
}
