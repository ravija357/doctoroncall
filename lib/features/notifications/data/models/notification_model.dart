import 'package:doctoroncall/features/notifications/domain/entities/notification.dart' as entity;

class NotificationModel extends entity.Notification {
  const NotificationModel({
    required super.id,
    required super.message,
    required super.type,
    super.relatedId,
    super.link,
    required super.isRead,
    required super.createdAt,
  });

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
}
