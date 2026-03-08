import 'package:flutter_test/flutter_test.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model.dart';
import 'package:doctoroncall/features/notifications/domain/entities/notification.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tNotificationModel = NotificationModel(
    id: 'note1',
    message: 'Test message',
    type: 'INFO',
    relatedId: 'rel1',
    link: 'http://link',
    isRead: false,
    createdAt: tDate,
  );

  group('NotificationModel Tests', () {
    test('should be a subclass of AppNotification entity', () async {
      expect(tNotificationModel, isA<AppNotification>());
    });

    test('fromJson should return a valid model', () async {
      final Map<String, dynamic> jsonMap = {
        '_id': 'note1',
        'message': 'Test message',
        'type': 'ALERT',
        'relatedId': 'rel1',
        'link': 'http://link',
        'isRead': true,
        'createdAt': tDate.toIso8601String(),
      };

      final result = NotificationModel.fromJson(jsonMap);

      expect(result.id, 'note1');
      expect(result.message, 'Test message');
      expect(result.type, 'ALERT');
      expect(result.relatedId, 'rel1');
      expect(result.isRead, true);
    });

    test('fromJson should handle missing fields', () async {
      final Map<String, dynamic> jsonMap = {'id': 'note2'};

      final result = NotificationModel.fromJson(jsonMap);

      expect(result.id, 'note2');
      expect(result.message, '');
      expect(result.type, 'INFO');
      expect(result.isRead, false);
      expect(result.relatedId, null);
    });

    test('toJson should return a JSON map containing required data', () async {
      final result = tNotificationModel.toJson();

      final expectedMap = {
        'message': 'Test message',
        'type': 'INFO',
        'relatedId': 'rel1',
        'link': 'http://link',
        'isRead': false,
      };

      expect(result, expectedMap);
    });

    test(
      'toHiveMap should return map with correct keys for local storage',
      () async {
        final result = tNotificationModel.toHiveMap();

        expect(result['id'], 'note1');
        expect(result['message'], 'Test message');
        expect(result['createdAt'], tDate.toIso8601String());
      },
    );

    test('fromHiveMap should return a valid model from dynamic map', () async {
      final Map<dynamic, dynamic> hiveMap = {
        'id': 'note1',
        'message': 'Test message',
        'type': 'INFO',
        'relatedId': 'rel1',
        'link': 'http://link',
        'isRead': false,
        'createdAt': tDate.toIso8601String(),
      };

      final result = NotificationModel.fromHiveMap(hiveMap);

      expect(result.id, 'note1');
      expect(result.message, 'Test message');
      expect(result.type, 'INFO');
      expect(result.createdAt, tDate);
    });

    test(
      'fromHiveMap should provide fallback values on missing data',
      () async {
        final Map<dynamic, dynamic> hiveMap = {};

        final result = NotificationModel.fromHiveMap(hiveMap);

        expect(result.id, '');
        expect(result.message, '');
        expect(result.type, 'INFO');
        expect(result.isRead, false);
      },
    );
  });
}
