import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_boxes.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  Future<void> signUp(UserModel user, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: {
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'password': password,
          'role': user.role, // 'PATIENT' or 'DOCTOR' based on your index.ts routes/models
        },
      );
      
      if (response.statusCode != 201) {
        throw ServerException(message: 'Failed to sign up');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Signup failed');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // The backend should return { token: '...', user: {...} }
        final token = data['token'];
        
        // Save the JWT token
        await apiClient.secureStorage.write(key: 'jwt_token', value: token);
        // Save the user ID for socket connections
        final user = data['user'];
        final userId = user['id'];
        await apiClient.secureStorage.write(key: 'user_id', value: userId);

        // Sync user info to Hive for real-time UI
        final box = Hive.box(HiveBoxes.users);
        await box.put('userId', user['id']);
        await box.put('firstName', user['firstName']);
        await box.put('lastName', user['lastName']);
        await box.put('email', user['email']);
        await box.put('role', user['role']);

        // Return the user model
        return UserModel.fromMap(data['user']);
      } else {
        throw ServerException(message: 'Failed to login');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Login failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    // Delete the token and user ID
    await apiClient.secureStorage.delete(key: 'jwt_token');
    await apiClient.secureStorage.delete(key: 'user_id');
  }
}
