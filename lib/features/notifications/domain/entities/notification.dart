import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String message;
  final String type; // 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR'
  final String? relatedId;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.message,
    required this.type,
    this.relatedId,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, message, type, relatedId, link, isRead, createdAt];
}
