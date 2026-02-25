import 'package:doctoroncall/features/doctors/data/datasources/doctor_remote_data_source.dart';
import 'package:doctoroncall/features/doctors/data/datasources/doctor_local_data_source.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remoteDataSource;
  final DoctorLocalDataSource localDataSource;

  DoctorRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Doctor>> getDoctors() async {
    try {
      final doctors = await remoteDataSource.getDoctors();
      // Cache on success
      await localDataSource.cacheDoctors(doctors);
      return doctors;
    } catch (e) {
      // Fallback to cache
      final cached = localDataSource.getCachedDoctors();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }
}
