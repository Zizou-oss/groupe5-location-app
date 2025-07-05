import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location_app/screens/admin_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _role = 'renter'; // valeur par défaut
  bool _isLoading = false;

  final String baseUrl = 'http://192.168.100.136:3000';

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _email,
          'password': _password,
          'role': _role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('userId', data['userId']);
        await prefs.setString('userName', _email);

        // 🎯 Redirection selon le rôle
        if (_role == 'landlord') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          );
        } else if (_role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        }
      } else {
        final message = jsonDecode(response.body)['message'];
        throw Exception(message);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inscription")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => _email = val!,
                validator: (val) =>
                    val!.isEmpty ? 'Veuillez entrer un email' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                onSaved: (val) => _password = val!,
                validator: (val) =>
                    val!.length < 6 ? 'Mot de passe trop court' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _role,
                items: [
                  DropdownMenuItem(value: 'renter', child: Text("Locataire")),
                  DropdownMenuItem(value: 'landlord', child: Text("Bailleur")),
                  DropdownMenuItem(value: 'admin', child: Text("Administrateur")),
                ],
                onChanged: (val) => setState(() => _role = val!),
                decoration: InputDecoration(labelText: "Rôle"),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRegister,
                      child: Text("S'inscrire"),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: Text("J'ai déjà un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
