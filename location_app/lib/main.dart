import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart'; // Fil d'actualité des locataires
import 'screens/dashboard_screen.dart'; // Tableau de bord des bailleurs

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(), // Pour locataires
        '/dashboard': (context) => DashboardScreen(), // Pour bailleurs
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text("Erreur")),
          body: Center(child: Text("Page non trouvée")),
        ),
      ),
    );
  }
} 
