import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import '../bloc/appointment_state.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

part 'appointment_provider.g.dart';

@riverpod
class AppointmentNotifier extends _$AppointmentNotifier {
  late final AppointmentRepository _repository;
  late final ChatRepository _chatRepository;
  StreamSubscription? _syncSubscription;

  @override
  AppointmentState build() {
    _repository = sl<AppointmentRepository>();
    _chatRepository = sl<ChatRepository>();

    _syncSubscription = _chatRepository.appointmentSyncStream().listen((_) {
      syncAppointments();
    });

    ref.onDispose(() {
      _syncSubscription?.cancel();
    });

    return AppointmentInitial();
  }

  Future<void> loadAppointments(String userId) async {
    state = AppointmentLoading();
    try {
      final appointments = await _repository.getAppointments(userId);
      state = AppointmentsLoaded(appointments: appointments);
    } catch (e) {
      state = AppointmentError(message: e.toString());
    }
  }

  Future<void> loadDoctorAppointments() async {
    state = AppointmentLoading();
    try {
      final appointments = await _repository.getDoctorAppointments();
      state = DoctorAppointmentsLoaded(appointments: appointments);
    } catch (e) {
      state = AppointmentError(message: e.toString());
    }
  }

  Future<void> bookAppointment(dynamic appointment) async {
    state = AppointmentLoading();
    try {
      await _repository.bookAppointment(appointment);
      state = AppointmentSuccess();
    } catch (e) {
      state = AppointmentError(message: e.toString());
    }
  }

  Future<void> cancelAppointment(String appointmentId, String userId) async {
    try {
      await _repository.cancelAppointment(appointmentId);
      await loadAppointments(userId);
    } catch (e) {
      state = AppointmentError(message: e.toString());
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _repository.updateAppointmentStatus(appointmentId, status);
      await loadDoctorAppointments();
    } catch (e) {
      state = AppointmentError(message: e.toString());
    }
  }

  Future<void> loadAvailability(String doctorId, DateTime date) async {
    state = AppointmentLoading();
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final slots = await _repository.getAvailability(doctorId, dateStr);
      state = AvailabilityLoaded(slots: slots);
    } catch (e) {
      state = AppointmentError(message: e.toString());
    }
  }

  Future<void> syncAppointments() async {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    final String? role = userData is Map ? userData['role'] : box.get('role');

    if (role?.toLowerCase() == 'doctor') {
      await loadDoctorAppointments();
    } else {
      final String? userId = userData is Map ? userData['id'] : box.get('userId');
      if (userId != null) {
        await loadAppointments(userId);
      }
    }
  }
}
