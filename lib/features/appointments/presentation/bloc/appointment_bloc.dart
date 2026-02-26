import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository repository;
  final ChatRepository chatRepository;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _scheduleSyncSubscription;

  AppointmentBloc({
    required this.repository,
    required this.chatRepository,
  }) : super(AppointmentInitial()) {
    on<LoadAppointmentsRequested>(_onLoadAppointmentsRequested);
    on<LoadDoctorAppointmentsRequested>(_onLoadDoctorAppointmentsRequested);
    on<UpdateAppointmentStatusRequested>(_onUpdateAppointmentStatusRequested);
    on<BookAppointmentRequested>(_onBookAppointmentRequested);
    on<CancelAppointmentRequested>(_onCancelAppointmentRequested);
    on<LoadAvailabilityRequested>(_onLoadAvailabilityRequested);

    // Listen for real-time synchronization pings from other devices (Web/Mobile)
    _syncSubscription = chatRepository.appointmentSyncStream().listen((_) {
      add(const LoadDoctorAppointmentsRequested());
    });

    _scheduleSyncSubscription = chatRepository.scheduleSyncStream().listen((_) {
      print('[SOCKET] Schedule Sync Ping');
      // For doctors, refresh their own slots. For patients, they'd refresh the current picker.
      // Generic reload or specific date reload could be added here.
      add(const LoadDoctorAppointmentsRequested()); 
    });
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _scheduleSyncSubscription?.cancel();
    return super.close();
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

  Future<void> _onUpdateAppointmentStatusRequested(
    UpdateAppointmentStatusRequested event,
    Emitter<AppointmentState> emit,
  ) async {
    try {
      await repository.updateAppointmentStatus(event.appointmentId, event.status);
      add(const LoadDoctorAppointmentsRequested());
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
