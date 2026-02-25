import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'chat_contact_model.g.dart';

@HiveType(typeId: 4)
class ChatContact extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? image;

  @HiveField(3)
  final String role;

  @HiveField(4)
  final String email;

  @HiveField(5)
  final String? lastMessage;

  @HiveField(6)
  final DateTime? lastMessageTime;

  @HiveField(7)
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

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'role': role,
      'email': email,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unread': unread,
    };
  }

  factory ChatContact.fromHiveMap(Map<dynamic, dynamic> map) {
    return ChatContact(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      image: map['image'] as String?,
      role: map['role'] as String? ?? 'user',
      email: map['email'] as String? ?? '',
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.tryParse(map['lastMessageTime'].toString())
          : null,
      unread: map['unread'] as int? ?? 0,
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
