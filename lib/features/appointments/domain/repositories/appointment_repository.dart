import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointments(String userId);
  Future<List<Appointment>> getDoctorAppointments();
  Future<void> bookAppointment(Appointment appointment);
  Future<void> cancelAppointment(String appointmentId);
  Future<List<Map<String, dynamic>>> getAvailability(String doctorId, String date);
}
