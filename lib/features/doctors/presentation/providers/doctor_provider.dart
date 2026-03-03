import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/doctor_repository.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import '../bloc/doctor_state.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'dart:async';
import '../../domain/entities/schedule.dart';

part 'doctor_provider.g.dart';

@riverpod
class DoctorNotifier extends _$DoctorNotifier {
  late final DoctorRepository _doctorRepository;
  late final ChatRepository _chatRepository;
  final List<StreamSubscription> _subscriptions = [];

  @override
  DoctorState build() {
    _doctorRepository = sl<DoctorRepository>();
    _chatRepository = sl<ChatRepository>();

    _subscriptions.add(_chatRepository.doctorSyncStream().listen((_) {
      loadDoctors();
    }));

    _subscriptions.add(_chatRepository.scheduleSyncStream().listen((_) {
      loadDoctors();
    }));

    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
    });

    return DoctorInitial();
  }

  Future<void> loadDoctors() async {
    state = DoctorLoading();
    try {
      final doctors = await _doctorRepository.getDoctors();
      state = DoctorsLoaded(doctors: doctors);
    } catch (e) {
      state = DoctorError(message: e.toString());
    }
  }

  Future<void> updateSchedule(List<Map<String, dynamic>> schedules) async {
    state = DoctorLoading();
    try {
      final scheduleObjects = schedules.map((s) => Schedule(
        day: s['day'] as String,
        startTime: s['startTime'] as String,
        endTime: s['endTime'] as String,
        isOff: s['isOff'] as bool,
      )).toList();
      await _doctorRepository.updateSchedule(scheduleObjects);
      state = DoctorScheduleUpdated();
      await loadDoctors();
    } catch (e) {
      state = DoctorError(message: e.toString());
    }
  }
}
