import 'package:equatable/equatable.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object> get props => [];
}

class LoadAppointmentsRequested extends AppointmentEvent {
  final String userId;
  const LoadAppointmentsRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class LoadDoctorAppointmentsRequested extends AppointmentEvent {
  const LoadDoctorAppointmentsRequested();
}

class BookAppointmentRequested extends AppointmentEvent {
  final Appointment appointment;
  const BookAppointmentRequested({required this.appointment});

  @override
  List<Object> get props => [appointment];
}

class CancelAppointmentRequested extends AppointmentEvent {
  final String appointmentId;
  final String userId;
  const CancelAppointmentRequested({required this.appointmentId, required this.userId});

  @override
  List<Object> get props => [appointmentId, userId];
}
