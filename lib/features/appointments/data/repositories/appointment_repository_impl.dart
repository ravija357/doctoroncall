import 'package:doctoroncall/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:doctoroncall/features/appointments/data/datasources/appointment_local_data_source.dart';
import 'package:doctoroncall/features/appointments/data/models/appointment_model.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;
  final AppointmentLocalDataSource localDataSource;

  AppointmentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Appointment>> getAppointments(String userId) async {
    try {
      final appointments = await remoteDataSource.getAppointments(userId);
      await localDataSource.cacheAppointments(userId, appointments);
      return appointments;
    } catch (e) {
      final cached = localDataSource.getCachedAppointments(userId);
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Appointment>> getDoctorAppointments() async {
    try {
      final appointments = await remoteDataSource.getDoctorAppointments();
      final models = appointments.map((a) => AppointmentModel(
        id: a.id,
        doctorId: a.doctorId,
        patientId: a.patientId,
        dateTime: a.dateTime,
        startTime: a.startTime,
        endTime: a.endTime,
        status: a.status,
        reason: a.reason,
        notes: a.notes,
        doctorName: a.doctorName,
        specialization: a.specialization,
        hospital: a.hospital,
        doctorImage: a.doctorImage,
      )).toList();
      await localDataSource.cacheDoctorAppointments(models);
      return appointments;
    } catch (e) {
      final cached = localDataSource.getCachedDoctorAppointments();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<void> bookAppointment(Appointment appointment) async {
    final model = AppointmentModel(
      id: appointment.id,
      doctorId: appointment.doctorId,
      patientId: appointment.patientId,
      dateTime: appointment.dateTime,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      status: appointment.status,
      reason: appointment.reason,
      notes: appointment.notes,
    );
    await remoteDataSource.bookAppointment(model);
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await remoteDataSource.cancelAppointment(appointmentId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailability(String doctorId, String date) async {
    return remoteDataSource.getAvailability(doctorId, date);
  }
}
