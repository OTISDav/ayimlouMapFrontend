import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'map_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await AuthService.getToken();
    await Future.delayed(Duration(milliseconds: 600));
    if (token == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.restaurant, size: 90, color: Colors.teal),
          SizedBox(height: 16),
          Text('AyimolouMap', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Trouve l\'ayimolou près de toi', style: TextStyle(color: Colors.grey[700])),
        ]),
      ),
    );
  }
}
