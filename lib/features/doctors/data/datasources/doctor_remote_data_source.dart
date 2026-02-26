import 'package:dio/dio.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/features/doctors/data/models/doctor_model.dart';
import 'package:doctoroncall/features/doctors/data/models/schedule_model.dart';

abstract class DoctorRemoteDataSource {
  Future<List<DoctorModel>> getDoctors();
  Future<void> updateSchedule(List<ScheduleModel> schedules);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final ApiClient apiClient;

  DoctorRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<DoctorModel>> getDoctors() async {
    try {
      final response = await apiClient.dio.get('/doctors');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> doctorsJson = response.data['data'];
        return doctorsJson.map((json) => DoctorModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to load doctors');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateSchedule(List<ScheduleModel> schedules) async {
    try {
      final response = await apiClient.dio.put(
        '/doctors/profile/schedule',
        data: schedules.map((s) => s.toJson()).toList(),
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerException(message: 'Failed to update schedule');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Network error',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
