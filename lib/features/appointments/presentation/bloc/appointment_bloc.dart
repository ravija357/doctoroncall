import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final AppointmentRepository repository;
  final ChatRepository chatRepository;
  StreamSubscription? _syncSubscription;

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
    on<SyncAppointments>(_onSyncAppointments);

    _syncSubscription = chatRepository.appointmentSyncStream().listen((_) {
      add(const SyncAppointments());
    });
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
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

  Future<void> _onSyncAppointments(
    SyncAppointments event,
    Emitter<AppointmentState> emit,
  ) async {
    print('[SOCKET] AppointmentBloc: Processing SyncAppointments event');
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    final String? role = userData is Map ? userData['role'] : box.get('role');
    print('[SOCKET] AppointmentBloc: Detected role: $role');

    if (role?.toLowerCase() == 'doctor') {
      print('[SOCKET] AppointmentBloc: Triggering LoadDoctorAppointmentsRequested');
      add(const LoadDoctorAppointmentsRequested());
    } else {
      final String? userId = userData is Map ? userData['id'] : box.get('userId');
      print('[SOCKET] AppointmentBloc: User ID found: $userId');
      if (userId != null) {
        print('[SOCKET] AppointmentBloc: Triggering LoadAppointmentsRequested');
        add(LoadAppointmentsRequested(userId: userId));
      }
    }
  }
}
