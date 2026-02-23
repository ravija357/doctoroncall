import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getDoctors();
}
