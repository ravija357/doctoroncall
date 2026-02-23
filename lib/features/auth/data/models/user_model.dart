class UserModel {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // 'PATIENT' or 'DOCTOR'

  UserModel({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? map['_id']) as String?,
      firstName: map['firstName'] as String? ?? 'Unknown',
      lastName: map['lastName'] as String? ?? 'Unknown',
      email: map['email'] as String,
      role: map['role'] as String? ?? 'PATIENT',
    );
  }
}
