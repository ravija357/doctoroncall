import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'doctor_event.dart';
import 'doctor_state.dart';

class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository doctorRepository;
  final ChatRepository chatRepository;
  StreamSubscription? _syncSubscription;

  DoctorBloc({
    required this.doctorRepository,
    required this.chatRepository,
  }) : super(DoctorInitial()) {
    on<LoadDoctorsRequested>(_onLoadDoctorsRequested);
    on<UpdateDoctorScheduleRequested>(_onUpdateDoctorScheduleRequested);
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadDoctorsRequested(
      LoadDoctorsRequested event, Emitter<DoctorState> emit) async {
    emit(DoctorLoading());
    try {
      final doctors = await doctorRepository.getDoctors();
      emit(DoctorsLoaded(doctors: doctors));
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDoctorScheduleRequested(
      UpdateDoctorScheduleRequested event, Emitter<DoctorState> emit) async {
    emit(DoctorLoading());
    try {
      await doctorRepository.updateSchedule(event.schedules);
      emit(DoctorScheduleUpdated());
      // Refresh doctors to get the updated schedule in the list
      add(const LoadDoctorsRequested());
    } catch (e) {
      emit(DoctorError(message: e.toString()));
    }
  }
}
