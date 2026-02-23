import 'package:doctoroncall/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static String get baseUrl => '${ApiConstants.baseUrl}/api/auth';

  // iOS simulator: http://localhost:3001

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return response.statusCode == 201;
  }
}
