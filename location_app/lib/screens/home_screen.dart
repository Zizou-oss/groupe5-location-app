import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../providers/property_provider.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import 'property_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String _selectedCity = '';
  double _minPrice = 0;
  double _maxPrice = 5000;
  bool _showFilters = false;

  final List<String> _popularCities = [
    'Ouagadougou',
    'Bobo-Dioulasso',
    'Koudougou',
    'Banfora',
    'Tenkodogo',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _setupScrollListener();
    
    // Charger les propriétés au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchProperties(refresh: true);
    });
  }

  void _setupAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        // Charger plus de propriétés quand on approche de la fin
        context.read<PropertyProvider>().loadMoreProperties();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<PropertyProvider>().refreshProperties();
  }

  void _applyFilters() {
    final provider = context.read<PropertyProvider>();
    provider.applyFilters(
      city: _selectedCity.isEmpty ? null : _selectedCity,
      minPrice: _minPrice > 0 ? _minPrice : null,
      maxPrice: _maxPrice < 5000 ? _maxPrice : null,
    );
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = '';
      _minPrice = 0;
      _maxPrice = 5000;
    });
    context.read<PropertyProvider>().clearFilters();
  }

  void _onSearchChanged(String query) {
    context.read<PropertyProvider>().searchProperties(query);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Déconnexion'),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear API cache and navigation
      ApiService().clearCache();
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildSearchAndFilters()),
              _buildPropertiesList(),
            ],
          ),
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
          'Biens disponibles',
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
          icon: Icon(Icons.notifications_outlined),
          onPressed: () {
            CustomSnackBar.show(
              context,
              message: 'Notifications à venir',
              type: SnackBarType.info,
            );
          },
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualiser'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: _handleRefresh,
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.logout, color: AppTheme.errorColor),
                title: Text('Se déconnecter'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: _logout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppTheme.surfaceColor,
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          // Barre de recherche
          ModernTextField(
            controller: _searchController,
            hint: 'Rechercher par titre, ville...',
            prefixIcon: Icons.search,
            suffixIcon: _searchController.text.isNotEmpty
                ? Icons.clear
                : null,
            onChanged: _onSearchChanged,
            onSuffixIconTap: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
          
          SizedBox(height: AppTheme.spacing16),
          
          // Filtres rapides par ville
          SectionHeader(
            title: 'Villes populaires',
            action: TextButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_showFilters ? 'Masquer' : 'Plus de filtres'),
                  Icon(_showFilters 
                      ? Icons.expand_less 
                      : Icons.expand_more),
                ],
              ),
            ),
          ),
          
          // Chips pour les villes populaires
          Wrap(
            spacing: AppTheme.spacing8,
            children: _popularCities.map((city) {
              return ModernChip(
                label: city,
                icon: Icons.location_on,
                isSelected: _selectedCity == city,
                onTap: () {
                  setState(() {
                    _selectedCity = _selectedCity == city ? '' : city;
                  });
                  _applyFilters();
                },
              );
            }).toList(),
          ),
          
          // Filtres avancés
          if (_showFilters) ...[
            SizedBox(height: AppTheme.spacing16),
            _buildAdvancedFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return ModernCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres de prix',
            style: AppTheme.heading3,
          ),
          SizedBox(height: AppTheme.spacing16),
          
          Text(
            'Prix: ${_minPrice.toInt()} - ${_maxPrice.toInt()} FCFA',
            style: AppTheme.bodyMedium,
          ),
          
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AppTheme.primaryColor,
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          
          SizedBox(height: AppTheme.spacing16),
          
          Row(
            children: [
              Expanded(
                child: LoadingButton(
                  text: 'Appliquer',
                  onPressed: _applyFilters,
                ),
              ),
              SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: Text('Effacer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList() {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        if (propertyProvider.isLoading && propertyProvider.properties.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              height: 400,
              child: ModernLoadingIndicator(),
            ),
          );
        }

        if (propertyProvider.error != null) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Erreur de chargement',
              subtitle: propertyProvider.error!,
              buttonText: 'Réessayer',
              onButtonPressed: () {
                propertyProvider.clearError();
                propertyProvider.fetchProperties(refresh: true);
              },
            ),
          );
        }

        final properties = propertyProvider.properties;
        
        if (properties.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.home_outlined,
              title: 'Aucune propriété trouvée',
              subtitle: 'Essayez de modifier vos critères de recherche',
              buttonText: 'Effacer les filtres',
              onButtonPressed: _clearFilters,
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < properties.length) {
                  return _buildPropertyCard(properties[index]);
                } else if (propertyProvider.hasMoreData) {
                  return Container(
                    padding: EdgeInsets.all(AppTheme.spacing16),
                    child: Center(child: ModernLoadingIndicator(size: 30)),
                  );
                }
                return SizedBox.shrink();
              },
              childCount: properties.length + (propertyProvider.hasMoreData ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyCard(Property property) {
    final imageUrl = property.images.isNotEmpty 
        ? '${ApiService().toString().split('://')[1]}${property.images.first}'
        : '';

    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(propertyId: property.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de la propriété
          OptimizedNetworkImage(
            imageUrl: imageUrl,
            height: 200,
            width: double.infinity,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.borderRadius12),
              topRight: Radius.circular(AppTheme.borderRadius12),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et prix
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.title,
                        style: AppTheme.heading3,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Text(
                        '${property.price.toInt()} FCFA',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: AppTheme.spacing8),
                
                // Localisation et taille
                Row(
                  children: [
                    Icon(Icons.location_on, 
                         size: 16, 
                         color: AppTheme.textSecondary),
                    SizedBox(width: AppTheme.spacing4),
                    Text(
                      property.city,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (property.size != null) ...[
                      SizedBox(width: AppTheme.spacing16),
                      Icon(Icons.square_foot, 
                           size: 16, 
                           color: AppTheme.textSecondary),
                      SizedBox(width: AppTheme.spacing4),
                      Text(
                        property.size!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                
                if (property.description != null) ...[
                  SizedBox(height: AppTheme.spacing8),
                  Text(
                    property.description!,
                    style: AppTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                if (property.features.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacing12),
                  Wrap(
                    spacing: AppTheme.spacing4,
                    runSpacing: AppTheme.spacing4,
                    children: property.features.take(3).map((feature) {
                      return ModernChip(
                        label: feature,
                        backgroundColor: AppTheme.primaryLight,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
