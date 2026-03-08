import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model.dart';
import 'dart:io';

void main() {
  late NotificationLocalDataSource dataSource;
  final testPath = Directory.systemTemp.createTempSync().path;

  setUpAll(() async {
    Hive.init(testPath);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }
    await Hive.openBox(HiveBoxes.notifications);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    dataSource = NotificationLocalDataSource();
    await dataSource.clearCache();
  });

  group('NotificationLocalDataSource Tests', () {
    final tNotification = NotificationModel(
      id: 'note1',
      message: 'Hello Reminder',
      type: 'INFO',
      isRead: false,
      createdAt: DateTime(2023, 1, 1),
    );

    test(
      'getCachedNotifications should return empty list and 0 unread initially',
      () {
        final result = dataSource.getCachedNotifications();
        expect(result['notifications'], isEmpty);
        expect(result['unreadCount'], 0);
      },
    );

    test('cacheNotifications should store data correctly', () async {
      await dataSource.cacheNotifications([tNotification], 5);

      final result = dataSource.getCachedNotifications();

      expect(result['unreadCount'], 5);
      final List<NotificationModel> list = result['notifications'];
      expect(list, isNotEmpty);
      expect(list.first.id, 'note1');
      expect(list.first.message, 'Hello Reminder');
    });

    test('clearCache should remove all stored notifications', () async {
      await dataSource.cacheNotifications([tNotification], 3);

      await dataSource.clearCache();

      final result = dataSource.getCachedNotifications();
      expect(result['notifications'], isEmpty);
      // Depending on clear logic, default might still return 0.
      expect(result['unreadCount'], 0);
    });
  });
}
