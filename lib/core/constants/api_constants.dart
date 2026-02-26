// class ApiConstants {
//   static const String baseUrl = "http://YOUR_SERVER_IP:5000";
// }

import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    // Both physical devices and simulators on the same WiFi
    // can access this local IP address.
    return "http://192.168.1.71:3001";
  }
}
