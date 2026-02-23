import 'package:equatable/equatable.dart';

class ChatContact extends Equatable {
  final String id;
  final String name;
  final String? image;
  final String role;
  final String email;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unread;

  const ChatContact({
    required this.id,
    required this.name,
    this.image,
    required this.role,
    required this.email,
    this.lastMessage,
    this.lastMessageTime,
    required this.unread,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      image: json['image']?.toString(),
      role: json['role']?.toString() ?? 'user',
      email: json['email']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString(),
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.tryParse(json['lastMessageTime'].toString()) 
          : null,
      unread: (json['unread'] is int) ? json['unread'] : (int.tryParse(json['unread']?.toString() ?? '0') ?? 0),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        image,
        role,
        email,
        lastMessage,
        lastMessageTime,
        unread,
      ];
}
