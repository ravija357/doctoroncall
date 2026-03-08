import 'package:flutter_test/flutter_test.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tChatContact = ChatContact(
    id: 'contact1',
    name: 'John Doe',
    image: 'img.jpg',
    role: 'doctor',
    email: 'test@doc.com',
    lastMessage: 'Hi',
    lastMessageTime: tDate,
    unread: 2,
  );

  group('ChatContact Model Tests', () {
    test('fromJson should parse standard JSON map properly', () async {
      final jsonMap = {
        'id': 'contact1',
        'name': 'John Doe',
        'image': 'img.jpg',
        'role': 'doctor',
        'email': 'test@doc.com',
        'lastMessage': 'Hi',
        'lastMessageTime': tDate.toIso8601String(),
        'unread': 2,
      };

      final result = ChatContact.fromJson(jsonMap);

      expect(result.id, 'contact1');
      expect(result.name, 'John Doe');
      expect(result.role, 'doctor');
      expect(result.unread, 2);
      expect(result.lastMessageTime, tDate);
    });

    test(
      'fromJson should provide fallback for nulls or missing fields',
      () async {
        final jsonMap = <String, dynamic>{};

        final result = ChatContact.fromJson(jsonMap);

        expect(result.id, '');
        expect(result.name, 'Unknown');
        expect(result.role, 'user');
        expect(result.unread, 0);
        expect(result.lastMessage, null);
      },
    );

    test('fromJson should parse string unread count gracefully', () async {
      final jsonMap = {'unread': '5'};

      final result = ChatContact.fromJson(jsonMap);
      expect(result.unread, 5);
    });

    test('toHiveMap should output correct map', () async {
      final result = tChatContact.toHiveMap();

      expect(result['id'], 'contact1');
      expect(result['name'], 'John Doe');
      expect(result['unread'], 2);
      expect(result['lastMessageTime'], tDate.toIso8601String());
    });

    test('fromHiveMap should parse dynamic maps', () async {
      final Map<dynamic, dynamic> hiveMap = {
        'id': 'contact1',
        'name': 'John Doe',
        'image': 'img.jpg',
        'role': 'doctor',
        'email': 'test@doc.com',
        'lastMessage': 'Hi',
        'lastMessageTime': tDate.toIso8601String(),
        'unread': 2,
      };

      final result = ChatContact.fromHiveMap(hiveMap);

      expect(result.id, 'contact1');
      expect(result.name, 'John Doe');
      expect(result.image, 'img.jpg');
      expect(result.unread, 2);
    });

    test('fromHiveMap should handle empty maps', () async {
      final Map<dynamic, dynamic> hiveMap = {};

      final result = ChatContact.fromHiveMap(hiveMap);

      expect(result.id, '');
      expect(result.name, 'Unknown');
      expect(result.role, 'user');
      expect(result.unread, 0);
    });

    test('props should include all field properties', () {
      expect(tChatContact.props, [
        'contact1',
        'John Doe',
        'img.jpg',
        'doctor',
        'test@doc.com',
        'Hi',
        tDate,
        2,
      ]);
    });
  });
}
