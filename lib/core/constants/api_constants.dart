// class ApiConstants {
//   static const String baseUrl = "http://YOUR_SERVER_IP:5000";
// }

import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://192.168.1.67:3001";
    } else {
      return "http://192.168.1.67:3001";
    }
  }
}
