import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_boxes.dart';
import '../../../../core/constants/api_constants.dart';

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
          'role': user.role,
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
        final token = data['token'];
        
        // Save the JWT token
        await apiClient.secureStorage.write(key: 'jwt_token', value: token);
        // Save the user ID for socket connections
        final user = data['user'];
        final userId = user['id'];
        await apiClient.secureStorage.write(key: 'user_id', value: userId);

        // Build the UserModel
        final userModel = UserModel.fromMap(data['user']);

        // Cache full UserModel in Hive
        final box = Hive.box(HiveBoxes.users);
        await box.put('currentUser', userModel.toMap());

        return userModel;
      } else {
        throw ServerException(message: 'Failed to login');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Login failed');
    } catch (e) {
      rethrow;
    }
  }

  /// Read the cached user from Hive for auto-login
  Future<UserModel?> getCachedUser() async {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    if (userData == null) return null;

    // Also check if JWT token still exists
    final token = await apiClient.secureStorage.read(key: 'jwt_token');
    if (token == null) return null;

    return UserModel.fromMap(Map<dynamic, dynamic>.from(userData));
  }

  Future<void> logout() async {
    // Delete the token and user ID
    await apiClient.secureStorage.delete(key: 'jwt_token');
    await apiClient.secureStorage.delete(key: 'user_id');

    // Clear all Hive boxes
    await Hive.box(HiveBoxes.users).clear();
    if (Hive.isBoxOpen(HiveBoxes.appointments)) {
      await Hive.box(HiveBoxes.appointments).clear();
    }
    if (Hive.isBoxOpen(HiveBoxes.doctors)) {
      await Hive.box(HiveBoxes.doctors).clear();
    }
    if (Hive.isBoxOpen(HiveBoxes.notifications)) {
      await Hive.box(HiveBoxes.notifications).clear();
    }
    if (Hive.isBoxOpen(HiveBoxes.chatContacts)) {
      await Hive.box(HiveBoxes.chatContacts).clear();
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await apiClient.dio.get('/auth/me');
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final userModel = UserModel.fromMap(userData);

        // Update cache
        final box = Hive.box(HiveBoxes.users);
        await box.put('currentUser', userModel.toMap());
        
        // Also update loose fields for compatibility
        await box.put('firstName', userModel.firstName);
        await box.put('lastName', userModel.lastName);
        await box.put('email', userModel.email);
        await box.put('profileImage', userModel.profileImage);

        return userModel;
      } else {
        throw ServerException(message: 'Failed to fetch profile');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch profile');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.put(
        '/auth/${await apiClient.secureStorage.read(key: 'user_id')}',
        data: data,
      );

      if (response.statusCode == 200) {
        final userData = response.data['data'];
        final userModel = UserModel.fromMap(userData);

        // Update cache
        final box = Hive.box(HiveBoxes.users);
        await box.put('currentUser', userModel.toMap());
        
        // Also update loose fields for compatibility
        await box.put('firstName', userModel.firstName);
        await box.put('lastName', userModel.lastName);
        await box.put('email', userModel.email);
        await box.put('profileImage', userModel.profileImage);

        return userModel;
      } else {
        throw ServerException(message: 'Failed to update profile');
      }
    } on DioException catch (e) {
      throw ServerException(message: e.response?.data['message'] ?? e.message ?? 'Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }
}
