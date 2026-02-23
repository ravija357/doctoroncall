import 'package:doctoroncall/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:doctoroncall/features/appointments/data/models/appointment_model.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Appointment>> getAppointments(String userId) async {
    return await remoteDataSource.getAppointments(userId);
  }

  @override
  Future<List<Appointment>> getDoctorAppointments() async {
    return await remoteDataSource.getDoctorAppointments();
  }

  @override
  Future<void> bookAppointment(Appointment appointment) async {
    final model = AppointmentModel(
      id: appointment.id,
      doctorId: appointment.doctorId,
      patientId: appointment.patientId,
      dateTime: appointment.dateTime,
      status: appointment.status,
      notes: appointment.notes,
    );
    await remoteDataSource.bookAppointment(model);
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await remoteDataSource.cancelAppointment(appointmentId);
  }
}
