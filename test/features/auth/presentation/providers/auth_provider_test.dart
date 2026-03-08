import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/features/auth/presentation/providers/auth_provider.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';
import 'package:doctoroncall/features/auth/data/models/user_model.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import '../../../../helpers/test_helpers.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late MockChatRepository mockChatRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockChatRepository = MockChatRepository();

    // AuthProvider uses GetIt (sl) to find its repository. We must setup sl for tests.
    sl.allowReassignment = true;
    sl.registerLazySingleton<AuthRepository>(() => mockRepository);
    sl.registerLazySingleton<ChatRepository>(() => mockChatRepository);

    when(
      mockChatRepository.doctorSyncStream(),
    ).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthProvider Tests', () {
    final tUserModel = UserModel(
      id: '1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@test.com',
      role: 'patient',
    );

    test('initial state should be AuthInitial', () {
      final state = container.read(authProvider);
      expect(state, isA<AuthInitial>());
    });

    test(
      'login should emit AuthLoading then AuthAuthenticated on success',
      () async {
        // arrange
        when(
          mockRepository.login(any, any),
        ).thenAnswer((_) async => tUserModel);

        // act
        final notifier = container.read(authProvider.notifier);
        final future = notifier.login('test@test.com', 'password');

        // state should be loading immediately after calling login
        expect(container.read(authProvider), isA<AuthLoading>());

        await future;

        // assert
        final finalState = container.read(authProvider);
        expect(finalState, isA<AuthAuthenticated>());
        if (finalState is AuthAuthenticated) {
          expect(finalState.user, equals(tUserModel));
        }
      },
    );

    test('login should emit AuthLoading then AuthError on failure', () async {
      // arrange
      when(mockRepository.login(any, any)).thenThrow(Exception('Login failed'));

      // act
      await container
          .read(authProvider.notifier)
          .login('test@test.com', 'wrongpassword');

      // assert
      final finalState = container.read(authProvider);
      expect(finalState, isA<AuthError>());
    });

    test(
      'logout should call repository and emit AuthUnauthenticated',
      () async {
        // arrange
        when(mockRepository.logout()).thenAnswer((_) async => Future.value());

        // act
        await container.read(authProvider.notifier).logout();

        // assert
        verify(mockRepository.logout());
        expect(container.read(authProvider), isA<AuthUnauthenticated>());
      },
    );
  });
}
