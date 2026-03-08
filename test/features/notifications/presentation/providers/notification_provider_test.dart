import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/notifications/presentation/providers/notification_provider.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:doctoroncall/features/notifications/domain/entities/notification.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/notifications/domain/repositories/notification_repository.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import '../../../../helpers/test_helpers.mocks.dart';
import 'dart:async';

void main() {
  late MockNotificationRepository mockNotificationRepository;
  late MockChatRemoteDataSource mockChatRemoteDataSource;
  late ProviderContainer container;

  setUp(() {
    mockNotificationRepository = MockNotificationRepository();
    mockChatRemoteDataSource = MockChatRemoteDataSource();

    sl.allowReassignment = true;
    sl.registerLazySingleton<NotificationRepository>(
      () => mockNotificationRepository,
    );
    sl.registerLazySingleton<ChatRemoteDataSource>(
      () => mockChatRemoteDataSource,
    );

    when(
      mockChatRemoteDataSource.notificationStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockChatRemoteDataSource.notificationSyncStream,
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('NotificationProvider Tests', () {
    final tNotificationMap = {
      'notifications': <AppNotification>[],
      'unreadCount': 0,
    };

    test('initial state should be NotificationInitial', () {
      final state = container.read(notificationNotifierProvider);
      expect(state, isA<NotificationInitial>());
    });

    test(
      'loadNotifications should emit loading and then loaded state',
      () async {
        // arrange
        when(
          mockNotificationRepository.getNotifications(),
        ).thenAnswer((_) async => tNotificationMap);

        // act
        final notifier = container.read(notificationNotifierProvider.notifier);
        final future = notifier.loadNotifications();

        expect(
          container.read(notificationNotifierProvider),
          isA<NotificationLoading>(),
        );

        await future;

        final finalState = container.read(notificationNotifierProvider);
        expect(finalState, isA<NotificationsLoaded>());
      },
    );

    test('markAsRead should call repo and reload notifications', () async {
      // arrange
      when(
        mockNotificationRepository.markAsRead(any),
      ).thenAnswer((_) async => Future.value());
      when(
        mockNotificationRepository.getNotifications(),
      ).thenAnswer((_) async => tNotificationMap);

      // act
      await container
          .read(notificationNotifierProvider.notifier)
          .markAsRead('1');

      // assert
      verify(mockNotificationRepository.markAsRead('1')).called(1);
      verify(mockNotificationRepository.getNotifications()).called(1);
    });

    test('error handling should emit NotificationError', () async {
      // arrange
      when(
        mockNotificationRepository.getNotifications(),
      ).thenThrow(Exception('Failed'));

      // act
      await container
          .read(notificationNotifierProvider.notifier)
          .loadNotifications();

      // assert
      expect(
        container.read(notificationNotifierProvider),
        isA<NotificationError>(),
      );
    });
  });
}
