import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/core/providers/lock_provider.dart';
import 'package:doctoroncall/core/providers/biometric_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'biometric_mocks.mocks.dart';

// Create a mock box
class MockBox extends Mock implements Box {}

void main() {
  late MockBiometricService mockBiometricService;
  late MockFlutterSecureStorage mockSecureStorage;
  late ProviderContainer container;

  setUp(() async {
    mockBiometricService = MockBiometricService();
    mockSecureStorage = MockFlutterSecureStorage();

    // Mock Hive behavior
    Hive.init('.');
    await Future.microtask(() {}); // Await event loop
    try {
      if (!Hive.isBoxOpen(HiveBoxes.users)) {
        await Hive.openBox(HiveBoxes.users);
      }
    } catch (e) {
      // Ignore
    }

    when(
      mockSecureStorage.read(key: 'biometric_enabled'),
    ).thenAnswer((_) async => 'false');

    container = ProviderContainer(
      overrides: [
        biometricServiceProvider.overrideWithValue(mockBiometricService),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('Initial state should be false when biometric is disabled', () async {
    // Wait for the provider to complete its async build
    final lockState = await container.read(lockProvider.future);
    expect(lockState, false);

    final lockNotifier = container.read(lockProvider.notifier);
    expect(lockNotifier.isBiometricEnabled, false);
  });

  test(
    'Initial state should be true when biometric is enabled in storage',
    () async {
      when(
        mockSecureStorage.read(key: 'biometric_enabled'),
      ).thenAnswer((_) async => 'true');

      final testContainer = ProviderContainer(
        overrides: [
          biometricServiceProvider.overrideWithValue(mockBiometricService),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
        ],
      );

      final lockState = await testContainer.read(lockProvider.future);
      expect(lockState, true);
      expect(
        testContainer.read(lockProvider.notifier).isBiometricEnabled,
        true,
      );
    },
  );

  test('setBiometricEnabled should update state and storage', () async {
    await container.read(lockProvider.future); // Wait for init
    final lockNotifier = container.read(lockProvider.notifier);

    await lockNotifier.setBiometricEnabled(true);

    verify(
      mockSecureStorage.write(key: 'biometric_enabled', value: 'true'),
    ).called(1);
    expect(lockNotifier.isBiometricEnabled, true);
  });

  group('unlock', () {
    test(
      'unlock should return true and set state to false if biometric disabled',
      () async {
        await container.read(lockProvider.future); // Wait for init
        final lockNotifier = container.read(lockProvider.notifier);

        final result = await lockNotifier.unlock();

        expect(result, true);
        expect(container.read(lockProvider).value, false);
        verifyNever(mockBiometricService.authenticate());
      },
    );

    test(
      'unlock should call authenticate and update state on success',
      () async {
        when(
          mockSecureStorage.read(key: 'biometric_enabled'),
        ).thenAnswer((_) async => 'true');

        final testContainer = ProviderContainer(
          overrides: [
            biometricServiceProvider.overrideWithValue(mockBiometricService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        await testContainer.read(lockProvider.future); // Wait for init
        when(mockBiometricService.authenticate()).thenAnswer((_) async => true);

        final lockNotifier = testContainer.read(lockProvider.notifier);
        expect(
          testContainer.read(lockProvider).value,
          true,
        ); // Initially locked

        final result = await lockNotifier.unlock();

        expect(result, true);
        expect(testContainer.read(lockProvider).value, false);
        verify(mockBiometricService.authenticate()).called(1);
      },
    );

    test(
      'unlock should return false and keep state locked on failure',
      () async {
        when(
          mockSecureStorage.read(key: 'biometric_enabled'),
        ).thenAnswer((_) async => 'true');

        final testContainer = ProviderContainer(
          overrides: [
            biometricServiceProvider.overrideWithValue(mockBiometricService),
            secureStorageProvider.overrideWithValue(mockSecureStorage),
          ],
        );

        await testContainer.read(lockProvider.future); // Wait for init
        when(
          mockBiometricService.authenticate(),
        ).thenAnswer((_) async => false);

        final lockNotifier = testContainer.read(lockProvider.notifier);

        final result = await lockNotifier.unlock();

        expect(result, false);
        expect(testContainer.read(lockProvider).value, true); // Still locked
      },
    );
  });

  test('lock() should set state to true if biometric is enabled', () async {
    await container.read(lockProvider.future); // Wait for init
    final lockNotifier = container.read(lockProvider.notifier);
    await lockNotifier.setBiometricEnabled(true);

    // Provide stub for authenticate
    when(mockBiometricService.authenticate()).thenAnswer((_) async => true);

    // Simulate being unlocked first
    await lockNotifier.unlock();
    expect(container.read(lockProvider).value, false);

    lockNotifier.lock();
    expect(container.read(lockProvider).value, true);
  });
}
