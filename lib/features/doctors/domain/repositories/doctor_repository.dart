import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/doctors/domain/entities/schedule.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getDoctors();
  Future<void> updateSchedule(List<Schedule> schedules);
}
