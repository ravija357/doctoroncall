import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getAllDoctors();
  Future<Doctor> getDoctorById(String id);
  Future<List<Doctor>> searchDoctors(String query);
}
