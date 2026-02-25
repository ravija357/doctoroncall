import 'package:hive/hive.dart';
import 'package:doctoroncall/features/notifications/domain/entities/notification.dart' as entity;

@HiveType(typeId: 3)
class NotificationModel extends entity.Notification {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final String hiveMessage;

  @HiveField(2)
  final String hiveType;

  @HiveField(3)
  final String? hiveRelatedId;

  @HiveField(4)
  final String? hiveLink;

  @HiveField(5)
  final bool hiveIsRead;

  @HiveField(6)
  final String hiveCreatedAtStr;

  NotificationModel({
    required String id,
    required String message,
    required String type,
    String? relatedId,
    String? link,
    required bool isRead,
    required DateTime createdAt,
  })  : hiveId = id,
        hiveMessage = message,
        hiveType = type,
        hiveRelatedId = relatedId,
        hiveLink = link,
        hiveIsRead = isRead,
        hiveCreatedAtStr = createdAt.toIso8601String(),
        super(
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
