import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/doctors/presentation/providers/doctor_provider.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late MockDoctorRepository mockDoctorRepository;
  late MockChatRepository mockChatRepository;
  late ProviderContainer container;

  setUp(() {
    mockDoctorRepository = MockDoctorRepository();
    mockChatRepository = MockChatRepository();

    sl.allowReassignment = true;
    sl.registerLazySingleton<DoctorRepository>(() => mockDoctorRepository);
    sl.registerLazySingleton<ChatRepository>(() => mockChatRepository);

    when(
      mockChatRepository.doctorSyncStream(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockChatRepository.scheduleSyncStream(),
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('DoctorProvider Tests', () {
    final tDoctor = Doctor(
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
      schedules: [],
    );
    final tDoctorsList = [tDoctor];

    test('initial state should be DoctorInitial', () {
      final state = container.read(doctorNotifierProvider);
      expect(state, isA<DoctorInitial>());
    });

    test(
      'loadDoctors should emit DoctorLoading then DoctorsLoaded on success',
      () async {
        // arrange
        when(
          mockDoctorRepository.getDoctors(),
        ).thenAnswer((_) async => tDoctorsList);

        // act
        final notifier = container.read(doctorNotifierProvider.notifier);
        final future = notifier.loadDoctors();

        // assert loading state
        expect(container.read(doctorNotifierProvider), isA<DoctorLoading>());

        await future;

        // assert loaded state
        final finalState = container.read(doctorNotifierProvider);
        expect(finalState, isA<DoctorsLoaded>());
        if (finalState is DoctorsLoaded) {
          expect(finalState.doctors, equals(tDoctorsList));
        }
      },
    );

    test(
      'loadDoctors should emit DoctorLoading then DoctorError on failure',
      () async {
        // arrange
        when(
          mockDoctorRepository.getDoctors(),
        ).thenThrow(Exception('Fetch failed'));

        // act
        await container.read(doctorNotifierProvider.notifier).loadDoctors();

        // assert error state
        final finalState = container.read(doctorNotifierProvider);
        expect(finalState, isA<DoctorError>());
      },
    );

    test('updateSchedule should call repository and reload doctors', () async {
      // arrange
      when(
        mockDoctorRepository.updateSchedule(any),
      ).thenAnswer((_) async => Future.value());
      when(
        mockDoctorRepository.getDoctors(),
      ).thenAnswer((_) async => tDoctorsList); // for reload

      final schedules = [
        {
          'day': 'Monday',
          'startTime': '09:00',
          'endTime': '17:00',
          'isOff': false,
        },
      ];

      // act
      await container
          .read(doctorNotifierProvider.notifier)
          .updateSchedule(schedules);

      // assert
      verify(mockDoctorRepository.updateSchedule(any)).called(1);
      verify(mockDoctorRepository.getDoctors()).called(1);
    });
  });
}
