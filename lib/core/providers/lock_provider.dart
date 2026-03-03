import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'biometric_providers.dart';

part 'lock_provider.g.dart';

@Riverpod(keepAlive: true)
class Lock extends _$Lock {
  bool _isBiometricEnabled = false;

  @override
  FutureOr<bool> build() async {
    final storage = ref.watch(secureStorageProvider);
    final enabled = await storage.read(key: 'biometric_enabled');
    _isBiometricEnabled = enabled == 'true';
    return _isBiometricEnabled;
  }

  bool get isBiometricEnabled => _isBiometricEnabled;

  Future<void> setBiometricEnabled(bool enable) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'biometric_enabled', value: enable.toString());
    _isBiometricEnabled = enable;

    // Update the state if we are currently unlocked but just enabled biometrics
    if (enable && state.value == false) {
      state = const AsyncValue.data(true);
    }

    ref.notifyListeners(); // Keep this if external listeners depend on the getter
  }

  Future<bool> unlock() async {
    if (!_isBiometricEnabled) {
      state = const AsyncValue.data(false);
      return true;
    }

    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate();
    if (success) {
      state = const AsyncValue.data(false);
    }
    return success;
  }

  void lock() {
    if (_isBiometricEnabled) {
      state = const AsyncValue.data(true);
    }
  }
}
