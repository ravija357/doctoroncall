import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String? id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'text' | 'image' | 'file' | 'call_log'
  final String? fileUrl; // URL for image/file messages
  final String? fileName; // original file name for file type

  const Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = 'text',
    this.fileUrl,
    this.fileName,
  });

  @override
  List<Object?> get props =>
      [id, senderId, receiverId, content, timestamp, isRead, type, fileUrl, fileName];
}
