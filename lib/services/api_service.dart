import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vendor.dart';

class ApiService {
  static const String baseUrl = 'https://ayimoloumapbackend.onrender.com/api';

  static Future<List<Vendor>> fetchVendors({double? lat, double? lon, double radius = 5}) async {
    final uri = (lat != null && lon != null)
        ? Uri.parse('$baseUrl/vendors/nearby/?lat=$lat&lon=$lon&radius=$radius')
        : Uri.parse('$baseUrl/vendors/');

    final resp = await http.get(uri, headers: {
      'Content-Type': 'application/json',
    });

    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => Vendor.fromJson(e)).toList();
    }
    throw Exception('Failed to load vendors: ${resp.body}');
  }
}