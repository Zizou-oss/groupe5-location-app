import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadUserData();
  }

  void _setupAnimation() {
    _fadeController = AnimationController(
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

    _fadeController.forward();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('userName') ?? 'Utilisateur';
        _userEmail = prefs.getString('userEmail') ?? 'email@example.com';
        _userRole = prefs.getString('role') ?? 'renter';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'landlord':
        return 'Propriétaire';
      case 'admin':
        return 'Administrateur';
      case 'renter':
      default:
        return 'Locataire';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'landlord':
        return Icons.business;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'renter':
      default:
        return Icons.person;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.warningColor),
            SizedBox(width: AppTheme.spacing8),
            Text('Déconnexion'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear cache and navigate
      ApiService().clearCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const ModernLoadingIndicator()
            : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        children: [
                          _buildProfileCard(),
                          SizedBox(height: AppTheme.spacing16),
                          _buildSettingsSection(),
                          SizedBox(height: AppTheme.spacing16),
                          _buildAboutSection(),
                          SizedBox(height: AppTheme.spacing32),
                          _buildLogoutButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Mon Profil',
          style: AppTheme.heading3.copyWith(color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            CustomSnackBar.show(
              context,
              message: 'Modification du profil à venir',
              type: SnackBarType.info,
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return ModernCard(
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRoleIcon(_userRole),
              size: 40,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: AppTheme.spacing16),
          
          // User info
          Text(
            _userName,
            style: AppTheme.heading2,
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppTheme.spacing4),
          
          Text(
            _userEmail,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: AppTheme.spacing12),
          
          // Role badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius20),
            ),
            child: Text(
              _getRoleDisplayName(_userRole),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: AppTheme.heading3,
          ),
          
          SizedBox(height: AppTheme.spacing16),
          
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Gérer les notifications push',
            onTap: () {
              CustomSnackBar.show(
                context,
                message: 'Paramètres de notifications à venir',
                type: SnackBarType.info,
              );
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Confidentialité',
            subtitle: 'Paramètres de confidentialité',
            onTap: () {
              CustomSnackBar.show(
                context,
                message: 'Paramètres de confidentialité à venir',
                type: SnackBarType.info,
              );
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {
              CustomSnackBar.show(
                context,
                message: 'Sélection de langue à venir',
                type: SnackBarType.info,
              );
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Thème sombre',
            subtitle: 'Bientôt disponible',
            onTap: () {
              CustomSnackBar.show(
                context,
                message: 'Thème sombre en développement',
                type: SnackBarType.info,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À propos',
            style: AppTheme.heading3,
          ),
          
          SizedBox(height: AppTheme.spacing16),
          
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Aide & Support',
            subtitle: 'Centre d\'aide et FAQ',
            onTap: () {
              CustomSnackBar.show(
                context,
                message: 'Centre d\'aide à venir',
                type: SnackBarType.info,
              );
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'À propos de l\'app',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Location App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Aziz Thiombiano',
                children: [
                  SizedBox(height: AppTheme.spacing16),
                  Text(
                    'Application de location moderne avec fonctionnalités optimisées pour les propriétaires et locataires.',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
          
          _buildDivider(),
          
          _buildSettingsTile(
            icon: Icons.star_outline,
            title: 'Évaluer l\'app',
            subtitle: 'Donnez votre avis',
            onTap: () {
              CustomSnackBar.show(
                context,
                message: 'Merci pour votre soutien !',
                type: SnackBarType.success,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing8),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(title, style: AppTheme.bodyLarge),
      subtitle: Text(subtitle, style: AppTheme.bodySmall),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textHint,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Divider(
        color: AppTheme.dividerColor,
        thickness: 1,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return LoadingButton(
      text: 'Se déconnecter',
      icon: Icons.logout,
      backgroundColor: AppTheme.errorColor,
      onPressed: _handleLogout,
    );
  }
}