import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'widgets/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/property_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Optimize system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PropertyProvider(),
          lazy: false, // Pre-load for better performance
        ),
        // Add other providers here as needed
      ],
      child: MaterialApp(
        title: 'Location App',
        debugShowCheckedModeBanner: false,
        
        // Use our custom theme
        theme: AppTheme.lightTheme,
        
        // Performance optimizations
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Prevent font scaling beyond reasonable limits
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: child!,
          );
        },
        
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
        
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text("Erreur"),
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing24),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing24),
                    Text(
                      "Page non trouvée",
                      style: AppTheme.heading2.copyWith(
                        color: AppTheme.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.spacing8),
                    Text(
                      "La page que vous recherchez n'existe pas.\nVeuillez vérifier l'URL et réessayer.",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppTheme.spacing24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      ),
                      icon: Icon(Icons.home),
                      label: Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
