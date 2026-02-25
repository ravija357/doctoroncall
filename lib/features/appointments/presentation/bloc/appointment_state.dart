import 'package:equatable/equatable.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';

abstract class AppointmentState extends Equatable {
  const AppointmentState();

  @override
  List<Object> get props => [];
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentsLoaded extends AppointmentState {
  final List<Appointment> appointments;
  const AppointmentsLoaded({required this.appointments});

  @override
  List<Object> get props => [appointments];
}

class DoctorAppointmentsLoaded extends AppointmentState {
  final List<Appointment> appointments;
  const DoctorAppointmentsLoaded({required this.appointments});

  @override
  List<Object> get props => [appointments];
}

class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError({required this.message});

  @override
  List<Object> get props => [message];
}

class AppointmentSuccess extends AppointmentState {}

class AvailabilityLoaded extends AppointmentState {
  final List<Map<String, dynamic>> slots;
  const AvailabilityLoaded({required this.slots});

  @override
  List<Object> get props => [slots];
}
