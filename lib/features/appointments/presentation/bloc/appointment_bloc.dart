import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository repository;

  AppointmentBloc({required this.repository}) : super(AppointmentInitial()) {
    on<LoadAppointmentsRequested>(_onLoadAppointmentsRequested);
    on<LoadDoctorAppointmentsRequested>(_onLoadDoctorAppointmentsRequested);
    on<BookAppointmentRequested>(_onBookAppointmentRequested);
    on<CancelAppointmentRequested>(_onCancelAppointmentRequested);
    on<LoadAvailabilityRequested>(_onLoadAvailabilityRequested);
  }

  Future<void> _onLoadAppointmentsRequested(
    LoadAppointmentsRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final appointments = await repository.getAppointments(event.userId);
      emit(AppointmentsLoaded(appointments: appointments));
    } on ServerException catch (e) {
      emit(AppointmentError(message: e.message));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onLoadDoctorAppointmentsRequested(
    LoadDoctorAppointmentsRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final appointments = await repository.getDoctorAppointments();
      emit(DoctorAppointmentsLoaded(appointments: appointments));
    } on ServerException catch (e) {
      emit(AppointmentError(message: e.message));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onBookAppointmentRequested(
    BookAppointmentRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      await repository.bookAppointment(event.appointment);
      emit(AppointmentSuccess());
    } on ServerException catch (e) {
      emit(AppointmentError(message: e.message));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onCancelAppointmentRequested(
    CancelAppointmentRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      await repository.cancelAppointment(event.appointmentId);
      add(LoadAppointmentsRequested(userId: event.userId));
    } on ServerException catch (e) {
      emit(AppointmentError(message: e.message));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }

  Future<void> _onLoadAvailabilityRequested(
    LoadAvailabilityRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    emit(AppointmentLoading());
    try {
      final slots = await repository.getAvailability(event.doctorId, event.date);
      emit(AvailabilityLoaded(slots: slots));
    } on ServerException catch (e) {
      emit(AppointmentError(message: e.message));
    } catch (e) {
      emit(AppointmentError(message: e.toString()));
    }
  }
}
