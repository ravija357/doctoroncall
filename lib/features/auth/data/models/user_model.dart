class UserModel {
  final String email;
  final String password;

  UserModel({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}
