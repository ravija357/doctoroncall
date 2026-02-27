import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../data/models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserModel> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<void> logout() async {
    return await remoteDataSource.logout();
  }

  @override
  Future<void> signUp(UserModel user, String password) async {
    return await remoteDataSource.signUp(user, password);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    return await remoteDataSource.getCachedUser();
  }

  @override
  Future<UserModel> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return await remoteDataSource.updateProfile(data);
  }
}
