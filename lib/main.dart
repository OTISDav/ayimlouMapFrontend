import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './services/auth_service.dart';
import './providers/user_provider.dart';
import './screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final token = await AuthService.getToken();
  runApp(AyimolouApp(initialToken: token));
}

class AyimolouApp extends StatelessWidget {
  final String? initialToken;
  AyimolouApp({this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider()..loadToken(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AyimolouMap',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.teal,
          ),
        ),
        // ✅ Toujours aller sur la Map
        home: MapScreen(),
      ),
    );
  }
}
