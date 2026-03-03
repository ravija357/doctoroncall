import 'package:doctoroncall/features/notifications/domain/entities/notification.dart' as entity;
import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 3)
class NotificationModel extends entity.AppNotification {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String? relatedId;

  @HiveField(4)
  final String? link;

  @HiveField(5)
  final bool isRead;

  @HiveField(6)
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    this.relatedId,
    this.link,
    required this.isRead,
    required this.createdAt,
  }) : super(
          id: id,
          message: message,
          type: type,
          relatedId: relatedId,
          link: link,
          isRead: isRead,
          createdAt: createdAt,
        );

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'INFO',
      relatedId: json['relatedId'],
      link: json['link'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'link': link,
      'isRead': isRead,
    };
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'link': link,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'INFO',
      relatedId: map['relatedId'] as String?,
      link: map['link'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
