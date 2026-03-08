import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      return canAuthenticateWithBiometrics;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  Future<BiometricType?> getPreferredBiometricType() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      if (available.contains(BiometricType.face)) return BiometricType.face;
      if (available.contains(BiometricType.fingerprint))
        return BiometricType.fingerprint;
      if (available.contains(BiometricType.iris)) return BiometricType.iris;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> authenticate({String? reason, String? title}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason ?? 'Please authenticate to unlock the app',
        authMessages: <AuthMessages>[
          AndroidAuthMessages(signInTitle: title ?? 'Biometric Login'),
          const IOSAuthMessages(cancelButton: 'Cancel'),
        ],
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
