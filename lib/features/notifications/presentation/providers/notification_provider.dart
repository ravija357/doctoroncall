import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:doctoroncall/features/notifications/domain/repositories/notification_repository.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model.dart';
import 'package:doctoroncall/core/di/injection_container.dart' as di;
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';

import 'package:doctoroncall/features/notifications/domain/entities/notification.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  late final NotificationRepository _repository;
  late final ChatRemoteDataSource _chatRemoteDataSource;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _syncSubscription;

  @override
  NotificationState build() {
    _repository = di.sl<NotificationRepository>();
    _chatRemoteDataSource = di.sl<ChatRemoteDataSource>();

    _notificationSubscription = _chatRemoteDataSource.notificationStream.listen((data) {
      if (data != null) {
        _handleNewNotification(NotificationModel.fromJson(data));
      }
    });

    _syncSubscription = _chatRemoteDataSource.notificationSyncStream.listen((_) {
      loadNotifications();
    });

    ref.onDispose(() {
      _notificationSubscription?.cancel();
      _syncSubscription?.cancel();
    });

    return NotificationInitial();
  }

  Future<void> loadNotifications() async {
    state = NotificationLoading();
    try {
      final result = await _repository.getNotifications();
      state = NotificationsLoaded(
        notifications: result['notifications'],
        unreadCount: result['unreadCount'],
      );
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      loadNotifications();
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      loadNotifications();
    } catch (e) {
      state = NotificationError(e.toString());
    }
  }

  void _handleNewNotification(NotificationModel entity) {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedList = [entity as dynamic, ...currentState.notifications].cast<AppNotification>();
      state = NotificationsLoaded(
        notifications: updatedList,
        unreadCount: currentState.unreadCount + 1,
      );
    } else {
      loadNotifications();
    }
  }
}
