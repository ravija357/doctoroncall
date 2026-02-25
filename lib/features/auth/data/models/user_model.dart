import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String firstName;

  @HiveField(2)
  final String lastName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String role; // 'PATIENT' or 'DOCTOR'

  @HiveField(5)
  final String? profileImage;

  UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? map['_id']) as String?,
      firstName: map['firstName'] as String? ?? 'Unknown',
      lastName: map['lastName'] as String? ?? 'Unknown',
      email: map['email'] as String,
      role: map['role'] as String? ?? 'PATIENT',
      profileImage: map['profileImage'] as String?,
    );
  }
}
