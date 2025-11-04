import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vendor.dart';
import 'auth_service.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator; change to your deployed URL when needed
  static const String baseUrl = 'https://ayimoloumapbackend.onrender.com/api';

  // Fetch all vendors or nearby if lat/lon provided
  static Future<List<Vendor>> fetchVendors({double? lat, double? lon, double radius = 5}) async {
    final uri = (lat != null && lon != null)
        ? Uri.parse('$baseUrl/vendors/nearby/?lat=$lat&lon=$lon&radius=$radius')
        : Uri.parse('$baseUrl/vendors/');
    final token = await AuthService.getToken();
    final resp = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.map((e) => Vendor.fromJson(e)).toList();
    }
    throw Exception('Failed to load vendors: ${resp.body}');
  }
}
