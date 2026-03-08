import 'dart:io' show Platform;

class ApiConstants {
  static const int port = 3001;

  static String get baseUrl {
    // iOS Simulator & macOS → localhost works directly
    // Android Emulator → 10.0.2.2 maps to the host machine's localhost
    // No manual IP changes needed when switching Wi-Fi networks!
    if (Platform.isAndroid) {
      // Use the local IP of your machine for physics devices
      // Android Emulator: "http://10.0.2.2:$port"
      // Physical Device: "http://192.168.1.94:$port"
      return "http://192.168.1.94:$port";
    } else {
      // iOS simulator, macOS desktop
      return "http://localhost:$port";
    }
  }
}
