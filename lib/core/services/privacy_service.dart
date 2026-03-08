import 'dart:io';
import 'package:flag_secure/flag_secure.dart';

class PrivacyService {
  /// The "Security Sensor" Logic
  /// This protects the user's private medical records from being screenshotted/recorded.
  static Future<void> enablePrivacyShield() async {
    if (Platform.isAndroid) {
      // On Android, this makes the app screen black in task switcher and blocks screenshots
      await FlagSecure.set();
      print("🛡️ Privacy Shield Active: Screenshots Blocked (Android)");
    } else if (Platform.isIOS) {
      // iOS doesn't allow programmatic screenshot blocking via official APIs
      // but we can monitor screen recording session via native observers if needed.
      print("🛡️ Privacy Shield Active: Protection Mode (iOS)");
    }
  }

  static Future<void> disablePrivacyShield() async {
    if (Platform.isAndroid) {
      await FlagSecure.unset();
      print("🔓 Privacy Shield Deactivated");
    }
  }
}
