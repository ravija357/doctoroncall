import 'package:hive/hive.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

import '../models/user_model.dart';

class AuthLocalDataSource {
  late final Box _usersBox;
  
  AuthLocalDataSource() {
    _usersBox = Hive.box(HiveBoxes.users);
  }

  Future<void> signUp(UserModel user) async {
    await _usersBox.put(user.email, user.toMap());
  }

  Future<UserModel?> login(String email, String password) async {
    final data = _usersBox.get(email);

    if (data == null) return null;

    final user = UserModel.fromMap(Map<String, dynamic>.from(data));

    if (user.password == password) {
      return user;
    }
    return null;
  }
}
