import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/features/appointments/data/models/appointment_model.dart';

class AppointmentLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.appointments);

  /// Get cached appointments for a user
  List<AppointmentModel> getCachedAppointments(String userId) {
    final raw = _box.get('appointments_$userId');
    if (raw == null) return [];
    final List<dynamic> list = raw;
    return list
        .map((e) => AppointmentModel.fromHiveMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  /// Cache appointments for a user
  Future<void> cacheAppointments(String userId, List<AppointmentModel> appointments) async {
    await _box.put(
      'appointments_$userId',
      appointments.map((a) => a.toHiveMap()).toList(),
    );
  }

  /// Get cached doctor appointments
  List<AppointmentModel> getCachedDoctorAppointments() {
    final raw = _box.get('doctor_appointments');
    if (raw == null) return [];
    final List<dynamic> list = raw;
    return list
        .map((e) => AppointmentModel.fromHiveMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  /// Cache doctor appointments
  Future<void> cacheDoctorAppointments(List<AppointmentModel> appointments) async {
    await _box.put(
      'doctor_appointments',
      appointments.map((a) => a.toHiveMap()).toList(),
    );
  }

  /// Clear all cached appointments
  Future<void> clearCache() async {
    await _box.clear();
  }
}
