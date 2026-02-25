import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/features/doctors/data/models/doctor_model.dart';

class DoctorLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.doctors);

  /// Get cached doctors list
  List<DoctorModel> getCachedDoctors() {
    final raw = _box.get('doctors_list');
    if (raw == null) return [];
    final List<dynamic> list = raw;
    return list
        .map((e) => DoctorModel.fromHiveMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  /// Cache doctors list
  Future<void> cacheDoctors(List<DoctorModel> doctors) async {
    await _box.put(
      'doctors_list',
      doctors.map((d) => d.toHiveMap()).toList(),
    );
  }

  /// Clear all cached doctors
  Future<void> clearCache() async {
    await _box.clear();
  }
}
