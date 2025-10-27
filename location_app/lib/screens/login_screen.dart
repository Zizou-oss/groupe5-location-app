import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'admin_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Navigation selon le rôle
      Widget nextScreen;
      switch (result['role']) {
        case 'admin':
          nextScreen = const AdminDashboardScreen();
          break;
        case 'landlord':
          nextScreen = const DashboardScreen();
          break;
        case 'renter':
        default:
          nextScreen = const HomeScreen();
          break;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => nextScreen,
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );

      CustomSnackBar.show(
        context,
        message: 'Connexion réussie ! Bienvenue ${result['userName']}',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacing24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      SizedBox(height: AppTheme.spacing32),
                      _buildLoginForm(),
                      SizedBox(height: AppTheme.spacing24),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppTheme.spacing20),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Icon(
            Icons.home_rounded,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: AppTheme.spacing20),
        Text(
          'Location App',
          style: AppTheme.heading1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppTheme.spacing8),
        Text(
          'Connectez-vous à votre compte',
          style: AppTheme.bodyLarge.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(AppTheme.spacing24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connexion',
              style: AppTheme.heading2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing24),
            ModernTextField(
              label: 'Email',
              hint: 'Saisissez votre email',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            SizedBox(height: AppTheme.spacing16),
            ModernTextField(
              label: 'Mot de passe',
              hint: 'Saisissez votre mot de passe',
              prefixIcon: Icons.lock_outline,
              suffixIcon: _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              controller: _passwordController,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              onSuffixIconTap: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: Implémenter mot de passe oublié
                    CustomSnackBar.show(
                      context,
                      message: 'Fonctionnalité à venir',
                      type: SnackBarType.info,
                    );
                  },
                  child: Text('Mot de passe oublié ?'),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing24),
            LoadingButton(
              text: 'Se connecter',
              isLoading: _isLoading,
              onPressed: _handleLogin,
              icon: Icons.login,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pas encore de compte ? ',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, _) => const RegisterScreen(),
                    transitionsBuilder: (context, animation, _, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Text(
                'S\'inscrire',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing16),
        Text(
          'Version 1.0.0',
          style: AppTheme.caption.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}