import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  String? _token;
  bool get isLogged => _token != null;
  String? get token => _token;

  Future<void> loadToken() async {
    _token = await AuthService.getToken();
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await AuthService.saveToken(token);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    await AuthService.logout();
    notifyListeners();
  }
}
