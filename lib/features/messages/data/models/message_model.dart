import 'package:doctoroncall/features/messages/domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.timestamp,
    super.isRead,
    super.type,
    super.fileUrl,
    super.fileName,
  });

  /// Safely extract the string ID from a field that may be:
  ///  - a plain String  (already an ID)
  ///  - a Map          (populated Mongoose object with _id field)
  ///  - null
  static String _extractId(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is Map) return value['_id']?.toString() ?? fallback;
    return value.toString();
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id']?.toString(),
      senderId: _extractId(json['sender']),
      receiverId: _extractId(json['receiver']),
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isRead: json['read'] == true,
      type: json['type']?.toString() ?? 'text',
      fileUrl: json['fileUrl']?.toString(),
      fileName: json['fileName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
