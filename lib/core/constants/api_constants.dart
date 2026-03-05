// class ApiConstants {
//   static const String baseUrl = "http://YOUR_SERVER_IP:5000";
// }

class ApiConstants {
  static String get baseUrl {
    // Both physical devices and simulators on the same WiFi
    // can access this IP.
    // IMPORTANT: If you change Wi-Fi networks (e.g., from Home to College),
    // you MUST update this IP address to your computer's new local IP on that network.
    // To find your IP on Mac: Open Terminal and run `ipconfig getifaddr en0`
    return "http://192.168.0.108:3001"; // <-- CHANGE THIS TO YOUR CURRENT WI-FI IP
  }
}
