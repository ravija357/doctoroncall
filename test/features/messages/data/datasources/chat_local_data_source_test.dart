import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';
import 'package:doctoroncall/features/messages/data/models/message_model.dart';
import 'dart:io';

void main() {
  late ChatLocalDataSource dataSource;
  final testPath = Directory.systemTemp.createTempSync().path;

  setUpAll(() async {
    Hive.init(testPath);
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ChatContactAdapter());
    }
    await Hive.openBox(HiveBoxes.chatContacts);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    dataSource = ChatLocalDataSource();
    await dataSource.clearCache();
  });

  group('ChatLocalDataSource Tests', () {
    final tContact = ChatContact(
      id: 'contact1',
      name: 'Dr. Test',
      role: 'doctor',
      email: 'a@a.com',
      unread: 0,
    );
    final tMessage = MessageModel(
      id: 'msg1',
      senderId: 'pat1',
      receiverId: 'doc1',
      content: 'Hello',
      type: 'text',
      timestamp: DateTime(2023, 1, 1),
      isRead: false,
    );

    test('getCachedContacts should return empty list initially', () {
      final result = dataSource.getCachedContacts();
      expect(result, isEmpty);
    });

    test(
      'cacheContacts should store and getCachedContacts should retrieve',
      () async {
        await dataSource.cacheContacts([tContact]);

        final result = dataSource.getCachedContacts();

        expect(result, isNotEmpty);
        expect(result.first.id, 'contact1');
      },
    );

    test('getCachedMessages should return empty list initially', () {
      final result = dataSource.getCachedMessages('doc1');
      expect(result, isEmpty);
    });

    test('cacheMessages should store messages per user id', () async {
      await dataSource.cacheMessages('doc1', [tMessage]);

      final result = dataSource.getCachedMessages('doc1');

      expect(result, isNotEmpty);
      expect(result.first.id, 'msg1');
      expect(result.first.content, 'Hello');
    });

    test('clearCache should remove all data', () async {
      await dataSource.cacheContacts([tContact]);
      await dataSource.cacheMessages('doc1', [tMessage]);

      await dataSource.clearCache();

      expect(dataSource.getCachedContacts(), isEmpty);
      expect(dataSource.getCachedMessages('doc1'), isEmpty);
    });
  });
}
