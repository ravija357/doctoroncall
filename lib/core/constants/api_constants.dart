// class ApiConstants {
//   static const String baseUrl = "http://YOUR_SERVER_IP:5000";
// }

class ApiConstants {
  static String get baseUrl {
    // Both physical devices and simulators on the same WiFi
    // can access this stable local hostname.
    return "http://Ravis-MacBook-Air.local:3001";
  }
}
