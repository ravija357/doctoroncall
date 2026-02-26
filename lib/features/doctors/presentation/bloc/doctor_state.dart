import 'package:equatable/equatable.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';

abstract class DoctorState extends Equatable {
  const DoctorState();

  @override
  List<Object?> get props => [];
}

class DoctorInitial extends DoctorState {}

class DoctorLoading extends DoctorState {}

class DoctorsLoaded extends DoctorState {
  final List<Doctor> doctors;

  const DoctorsLoaded({required this.doctors});

  @override
  List<Object?> get props => [doctors];
}

class DoctorError extends DoctorState {
  final String message;

  const DoctorError({required this.message});

  @override
  List<Object?> get props => [message];
}
class DoctorScheduleUpdated extends DoctorState {}
