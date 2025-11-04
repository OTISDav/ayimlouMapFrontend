import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'map_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => isLoading = true);
    try {
      await AuthService.login(username, password);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MapScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ' + e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 20),
            Text('Bienvenue', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Connecte-toi pour profiter des fonctionnalités avancées.', style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nom d\'utilisateur'),
                  onSaved: (val) => username = val!.trim(),
                  validator: (val) => val!.isEmpty ? 'Champ requis' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  onSaved: (val) => password = val!.trim(),
                  validator: (val) => val!.length < 6 ? '6 caractères min' : null,
                ),
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
                        child: Text('Se connecter')),
                SizedBox(height: 12),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())), child: Text('Pas de compte ? Inscris-toi'))
              ]),
            )
          ]),
        ),
      ),
    );
  }
}
