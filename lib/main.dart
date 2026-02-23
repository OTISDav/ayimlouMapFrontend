import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const AyimolouApp());
}

class AyimolouApp extends StatelessWidget {
  const AyimolouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AyimolouMap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5C2A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3EE),
      ),
      home: SplashScreen(),
    );
  }
}