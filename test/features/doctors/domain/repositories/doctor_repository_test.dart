import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/doctors/data/repositories/doctor_repository_impl.dart';
import 'package:doctoroncall/features/doctors/data/models/doctor_model.dart';
import 'package:doctoroncall/features/doctors/domain/entities/schedule.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late DoctorRepositoryImpl repository;
  late MockDoctorRemoteDataSource mockRemoteDataSource;
  late MockDoctorLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockDoctorRemoteDataSource();
    mockLocalDataSource = MockDoctorLocalDataSource();
    repository = DoctorRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('DoctorRepositoryImpl', () {
    final tDoctorModel = DoctorModel(
      id: '1',
      userId: 'user1',
      firstName: 'Test',
      lastName: 'Doc',
      specialization: 'Cardiology',
      experience: 5,
      bio: 'Bio',
      fees: 100.0,
      averageRating: 4.5,
      totalReviews: 10,
    );
    final tDoctorsList = [tDoctorModel];
    final tSchedule = Schedule(
      day: 'Monday',
      startTime: '09:00',
      endTime: '17:00',
      isOff: false,
    );

    test(
      'should return list of doctors when remote data source is successful',
      () async {
        // arrange
        when(
          mockRemoteDataSource.getDoctors(),
        ).thenAnswer((_) async => tDoctorsList);
        when(
          mockLocalDataSource.cacheDoctors(any),
        ).thenAnswer((_) async => Future.value());

        // act
        final result = await repository.getDoctors();

        // assert
        expect(result, equals(tDoctorsList));
        verify(mockRemoteDataSource.getDoctors());
        verify(mockLocalDataSource.cacheDoctors(tDoctorsList));
      },
    );

    test(
      'should update schedule completely using remote data source',
      () async {
        // arrange
        when(
          mockRemoteDataSource.updateSchedule(any),
        ).thenAnswer((_) async => Future.value());

        // act
        await repository.updateSchedule([tSchedule]);

        // assert
        verify(mockRemoteDataSource.updateSchedule(any));
      },
    );
  });
}
