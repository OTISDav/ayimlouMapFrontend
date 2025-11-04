import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'map_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String username = '', email = '', phone = '', password = '';
  bool isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => isLoading = true);
    try {
      await AuthService.register(username, email, phone, password);
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
      appBar: AppBar(title: Text('Inscription')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(children: [
            TextFormField(decoration: InputDecoration(labelText: 'Nom d\'utilisateur'), onSaved: (v) => username = v!.trim(), validator: (v) => v!.isEmpty ? 'Champ requis' : null),
            SizedBox(height: 12),
            TextFormField(decoration: InputDecoration(labelText: 'Email'), onSaved: (v) => email = v!.trim(), validator: (v) => v!.isEmpty ? 'Champ requis' : null),
            SizedBox(height: 12),
            TextFormField(decoration: InputDecoration(labelText: 'Téléphone'), onSaved: (v) => phone = v!.trim()),
            SizedBox(height: 12),
            TextFormField(decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: true, onSaved: (v) => password = v!.trim(), validator: (v) => v!.length < 6 ? '6 caractères min' : null),
            SizedBox(height: 20),
            isLoading ? Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _register, child: Text('Créer un compte'))
          ]),
        ),
      ),
    );
  }
}
