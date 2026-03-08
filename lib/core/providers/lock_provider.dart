import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_boxes.dart';
import 'biometric_providers.dart';

part 'lock_provider.g.dart';

@Riverpod(keepAlive: true)
class Lock extends _$Lock {
  bool _isBiometricEnabled = false;
  bool _isAuthenticating = false;
  DateTime? _lastUnlockTime;

  @override
  FutureOr<bool> build() async {
    final storage = ref.watch(secureStorageProvider);
    final enabled = await storage.read(key: 'biometric_enabled');
    _isBiometricEnabled = enabled == 'true';
    _lastUnlockTime = null; // Reset on build
    return _isBiometricEnabled;
  }

  DateTime? get lastUnlockTime => _lastUnlockTime;
  bool get isAuthenticating => _isAuthenticating;
  bool get isBiometricEnabled => _isBiometricEnabled;

  Future<List<BiometricType>> getAvailableBiometrics() async {
    final biometricService = ref.read(biometricServiceProvider);
    return biometricService.getAvailableBiometrics();
  }

  Future<BiometricType?> getPreferredBiometricType() async {
    final biometricService = ref.read(biometricServiceProvider);
    return biometricService.getPreferredBiometricType();
  }

  Future<bool> isBiometricLoginAvailable() async {
    final storage = ref.read(secureStorageProvider);
    final email = await storage.read(key: 'biometric_email');
    final pass = await storage.read(key: 'biometric_password');
    return email != null && pass != null && _isBiometricEnabled;
  }

  Future<void> saveBiometricCredential(String email, String password) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'biometric_email', value: email);
    await storage.write(key: 'biometric_password', value: password);
  }

  Future<void> setBiometricEnabled(bool enable) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'biometric_enabled', value: enable.toString());
    _isBiometricEnabled = enable;

    // Sync with Hive for logout logic consistency
    final userBox = Hive.box(HiveBoxes.users);
    final userData = userBox.get('currentUser');
    if (userData is Map) {
      final updatedUser = Map<String, dynamic>.from(userData);
      final preferences = Map<String, dynamic>.from(
        updatedUser['preferences'] ?? {},
      );
      preferences['biometricEnabled'] = enable;
      updatedUser['preferences'] = preferences;
      await userBox.put('currentUser', updatedUser);
    }

    // If disabling, clear credentials too for security
    if (!enable) {
      await storage.delete(key: 'biometric_email');
      await storage.delete(key: 'biometric_password');
    }

    if (enable && (state.value == null || state.value == false)) {
      state = const AsyncValue.data(true);
    }

    ref.notifyListeners();
  }

  Future<bool> unlock({String? reason, String? title}) async {
    if (!_isBiometricEnabled) {
      state = const AsyncValue.data(false);
      return true;
    }

    if (_isAuthenticating) return false;
    _isAuthenticating = true;

    try {
      final biometricService = ref.read(biometricServiceProvider);
      final success = await biometricService.authenticate(
        reason: reason,
        title: title,
      );
      if (success) {
        _lastUnlockTime = DateTime.now();
        state = const AsyncValue.data(false);
      }
      return success;
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<Map<String, String>?> getBiometricCredentials() async {
    final storage = ref.read(secureStorageProvider);
    final email = await storage.read(key: 'biometric_email');
    final pass = await storage.read(key: 'biometric_password');
    if (email != null && pass != null) {
      return {'email': email, 'password': pass};
    }
    return null;
  }

  void lock() {
    if (_isBiometricEnabled) {
      state = const AsyncValue.data(true);
    }
  }
}
