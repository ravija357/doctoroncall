import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/services/biometric_service.dart';

part 'biometric_providers.g.dart';

@riverpod
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService();
}

@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage();
}
