import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // NOTE: use 10.0.2.2 for Android emulator to reach localhost backend
  static const String baseUrl = 'https://ayimoloumapbackend.onrender.com/api';

  // Login -> returns response map (may include token under 'access' or 'token')
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/accounts/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['access'] ?? data['token'];
      if (token != null) await saveToken(token);
      return data;
    }
    throw Exception('Login failed: ${resp.body}');
  }

  // Register
  static Future<Map<String, dynamic>> register(String username, String email, String phone, String password) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/accounts/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'phone': phone, 'password': password}),
    );
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['access'] ?? data['token'];
      if (token != null) await saveToken(token);
      return data;
    }
    throw Exception('Register failed: ${resp.body}');
  }

  // Save token (public)
  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Logout
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
