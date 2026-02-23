import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../data/models/notification_model.dart';
import '../../domain/entities/notification.dart' as entity;
import '../../../messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  final ChatRemoteDataSource chatRemoteDataSource;
  StreamSubscription? _notificationSubscription;

  NotificationBloc({
    required this.repository,
    required this.chatRemoteDataSource,
  }) : super(NotificationInitial()) {
    on<LoadNotificationsRequested>(_onLoadNotifications);
    on<MarkNotificationReadRequested>(_onMarkRead);
    on<MarkAllAsReadRequested>(_onMarkAllRead);
    on<NewNotificationReceived>(_onNewNotification);

    _notificationSubscription = chatRemoteDataSource.notificationStream.listen((data) {
      if (data != null) {
        add(NewNotificationReceived(NotificationModel.fromJson(data)));
      }
    });
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final result = await repository.getNotifications();
      emit(NotificationsLoaded(
        notifications: result['notifications'],
        unreadCount: result['unreadCount'],
      ));
    } on ServerException catch (e) {
      emit(NotificationError(e.message));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkRead(
    MarkNotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await repository.markAsRead(event.id);
      add(LoadNotificationsRequested());
    } on ServerException catch (e) {
      emit(NotificationError(e.message));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> _onMarkAllRead(
    MarkAllAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await repository.markAllAsRead();
      add(LoadNotificationsRequested());
    } on ServerException catch (e) {
      emit(NotificationError(e.message));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void _onNewNotification(
    NewNotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedList = [event.notification, ...currentState.notifications];
      emit(NotificationsLoaded(
        notifications: updatedList,
        unreadCount: currentState.unreadCount + 1,
      ));
    } else {
      add(LoadNotificationsRequested());
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }
}
