import 'package:equatable/equatable.dart';
import '../../domain/entities/notification.dart' as entity;

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsRequested extends NotificationEvent {}

class MarkNotificationReadRequested extends NotificationEvent {
  final String id;
  const MarkNotificationReadRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllAsReadRequested extends NotificationEvent {}

class NewNotificationReceived extends NotificationEvent {
  final entity.Notification notification;
  const NewNotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class SyncNotifications extends NotificationEvent {
  const SyncNotifications();
}
