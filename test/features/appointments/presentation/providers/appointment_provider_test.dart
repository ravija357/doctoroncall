import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late MockAppointmentRepository mockAppointmentRepository;
  late MockChatRepository mockChatRepository;
  late ProviderContainer container;

  setUp(() {
    mockAppointmentRepository = MockAppointmentRepository();
    mockChatRepository = MockChatRepository();

    sl.allowReassignment = true;
    sl.registerLazySingleton<AppointmentRepository>(
      () => mockAppointmentRepository,
    );
    sl.registerLazySingleton<ChatRepository>(() => mockChatRepository);

    when(
      mockChatRepository.appointmentSyncStream(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockChatRepository.recordSyncStream(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockChatRepository.prescriptionSyncStream(),
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AppointmentProvider Tests', () {
    final tAppointment = Appointment(
      id: '1',
      doctorId: 'doc1',
      patientId: 'pat1',
      dateTime: DateTime.now(),
      startTime: '10:00',
      endTime: '10:30',
      status: 'pending',
      doctorName: 'Dr. Test',
    );
    final tAppointmentsList = [tAppointment];

    test('initial state should be AppointmentInitial', () {
      final state = container.read(appointmentNotifierProvider);
      expect(state, isA<AppointmentInitial>());
    });

    test(
      'loadAppointments should emit loading and then loaded state',
      () async {
        // arrange
        when(
          mockAppointmentRepository.getAppointments('pat1'),
        ).thenAnswer((_) async => tAppointmentsList);

        // act
        final notifier = container.read(appointmentNotifierProvider.notifier);
        final future = notifier.loadAppointments('pat1');

        expect(
          container.read(appointmentNotifierProvider),
          isA<AppointmentLoading>(),
        );

        await future;

        final finalState = container.read(appointmentNotifierProvider);
        expect(finalState, isA<AppointmentsLoaded>());
      },
    );

    test('bookAppointment should call repo and emit success', () async {
      // arrange
      when(
        mockAppointmentRepository.bookAppointment(any),
      ).thenAnswer((_) async => Future.value());

      // act
      await container
          .read(appointmentNotifierProvider.notifier)
          .bookAppointment(tAppointment);

      // assert
      verify(mockAppointmentRepository.bookAppointment(any)).called(1);
      expect(
        container.read(appointmentNotifierProvider),
        isA<AppointmentSuccess>(),
      );
    });

    test(
      'loadAvailability should emit AvailabilityLoaded on success',
      () async {
        // arrange
        final slots = [
          {'time': '10:00'},
        ];
        when(
          mockAppointmentRepository.getAvailability(any, any),
        ).thenAnswer((_) async => slots);

        // act
        await container
            .read(appointmentNotifierProvider.notifier)
            .loadAvailability('doc1', DateTime.now());

        // assert
        final finalState = container.read(appointmentNotifierProvider);
        expect(finalState, isA<AvailabilityLoaded>());
        if (finalState is AvailabilityLoaded) {
          expect(finalState.slots, equals(slots));
        }
      },
    );

    test('error handling should emit AppointmentError', () async {
      // arrange
      when(
        mockAppointmentRepository.getAppointments(any),
      ).thenThrow(Exception('Failed to load'));

      // act
      await container
          .read(appointmentNotifierProvider.notifier)
          .loadAppointments('pat1');

      // assert
      expect(
        container.read(appointmentNotifierProvider),
        isA<AppointmentError>(),
      );
    });
  });
}
