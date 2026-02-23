import 'package:dio/dio.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/features/appointments/data/models/appointment_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getAppointments(String userId);
  Future<List<AppointmentModel>> getDoctorAppointments();
  Future<void> bookAppointment(AppointmentModel appointment);
  Future<void> cancelAppointment(String appointmentId);
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final ApiClient apiClient;

  AppointmentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AppointmentModel>> getAppointments(String userId) async {
    try {
      final response = await apiClient.dio.get('/appointments/my-appointments');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to fetch appointments');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Failed to connect to server',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<AppointmentModel>> getDoctorAppointments() async {
    try {
      final response = await apiClient.dio.get('/appointments/doctor-appointments');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to fetch doctor appointments');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to connect',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> bookAppointment(AppointmentModel appointment) async {
    try {
      final response = await apiClient.dio.post(
        '/appointments',
        data: appointment.toJson(),
      );
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw ServerException(message: 'Failed to book appointment');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Failed to connect to server',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      final response = await apiClient.dio.patch('/appointments/$appointmentId/cancel');
      
      if (response.statusCode != 200) {
        throw ServerException(message: 'Failed to cancel appointment');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Failed to connect to server',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
