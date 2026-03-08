import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:doctoroncall/features/appointments/data/models/appointment_model.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late AppointmentRepositoryImpl repository;
  late MockAppointmentRemoteDataSource mockRemoteDataSource;
  late MockAppointmentLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockAppointmentRemoteDataSource();
    mockLocalDataSource = MockAppointmentLocalDataSource();
    repository = AppointmentRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('AppointmentRepositoryImpl', () {
    final tAppointmentModel = AppointmentModel(
      id: '1',
      doctorId: 'doc1',
      patientId: 'pat1',
      dateTime: DateTime.now(),
      startTime: '10:00',
      endTime: '10:30',
      status: 'pending',
    );
    final tAppointmentsList = [tAppointmentModel];

    test(
      'should return list of appointments and cache them on success',
      () async {
        // arrange
        when(
          mockRemoteDataSource.getAppointments('pat1'),
        ).thenAnswer((_) async => tAppointmentsList);
        when(
          mockLocalDataSource.cacheAppointments('pat1', any),
        ).thenAnswer((_) async => Future.value());

        // act
        final result = await repository.getAppointments('pat1');

        // assert
        expect(result, equals(tAppointmentsList));
        verify(mockRemoteDataSource.getAppointments('pat1'));
        verify(
          mockLocalDataSource.cacheAppointments('pat1', tAppointmentsList),
        );
      },
    );

    test('should book appointment using remote data source', () async {
      // arrange
      when(
        mockRemoteDataSource.bookAppointment(any),
      ).thenAnswer((_) async => Future.value());

      // act
      await repository.bookAppointment(tAppointmentModel);

      // assert
      verify(mockRemoteDataSource.bookAppointment(any));
    });
  });
}
