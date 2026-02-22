import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointments(String userId);
  Future<void> bookAppointment(Appointment appointment);
  Future<void> cancelAppointment(String appointmentId);
}
