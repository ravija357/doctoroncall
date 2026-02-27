import 'package:doctoroncall/features/doctors/domain/entities/schedule.dart';
import 'package:equatable/equatable.dart';

abstract class DoctorEvent extends Equatable {
  const DoctorEvent();

  @override
  List<Object> get props => [];
}

class LoadDoctorsRequested extends DoctorEvent {
  const LoadDoctorsRequested();
}

class UpdateDoctorScheduleRequested extends DoctorEvent {
  final List<Schedule> schedules;

  const UpdateDoctorScheduleRequested({required this.schedules});

  @override
  List<Object> get props => [schedules];
}

class SyncDoctors extends DoctorEvent {
  const SyncDoctors();
}

class SyncSchedule extends DoctorEvent {
  const SyncSchedule();
}
