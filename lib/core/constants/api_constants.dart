// class ApiConstants {
//   static const String baseUrl = "http://YOUR_SERVER_IP:5000";
// }

import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:3001";
    } else {
      return "http://localhost:3001";
    }
  }
}
