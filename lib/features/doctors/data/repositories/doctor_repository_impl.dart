import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';
import 'package:doctoroncall/features/doctors/data/datasources/doctor_remote_data_source.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;

  DoctorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Doctor>> getDoctors() async {
    return await remoteDataSource.getDoctors();
  }
}
