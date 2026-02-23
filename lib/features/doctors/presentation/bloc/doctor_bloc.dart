import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';
import 'doctor_event.dart';
import 'doctor_state.dart';

class DoctorBloc extends Bloc<DoctorEvent, DoctorState> {
  final DoctorRepository doctorRepository;

  DoctorBloc({required this.doctorRepository}) : super(DoctorInitial()) {
    on<LoadDoctorsRequested>(_onLoadDoctorsRequested);
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
}
