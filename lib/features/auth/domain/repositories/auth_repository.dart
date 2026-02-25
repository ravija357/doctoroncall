import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<void> signUp(UserModel user, String password);
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel?> getCachedUser();
}
