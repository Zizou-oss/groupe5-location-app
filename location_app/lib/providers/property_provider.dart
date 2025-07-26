import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../services/api_service.dart';

class PropertyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Property> _properties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  
  // Filters
  String? _cityFilter;
  double? _minPriceFilter;
  double? _maxPriceFilter;
  
  // Getters
  List<Property> get properties => _filteredProperties.isEmpty ? _properties : _filteredProperties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  
  // Filter getters
  String? get cityFilter => _cityFilter;
  double? get minPriceFilter => _minPriceFilter;
  double? get maxPriceFilter => _maxPriceFilter;

  Future<void> fetchProperties({
    bool refresh = false,
    String? city,
    double? minPrice,
    double? maxPrice,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _properties.clear();
      _filteredProperties.clear();
      _hasMoreData = true;
    }

    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getProperties(
        city: city ?? _cityFilter,
        minPrice: minPrice ?? _minPriceFilter,
        maxPrice: maxPrice ?? _maxPriceFilter,
        page: _currentPage,
        limit: 10,
      );

      final List<dynamic> propertyList = response['properties'] ?? [];
      final pagination = response['pagination'];
      
      final newProperties = propertyList.map((json) => Property.fromJson(json)).toList();
      
      if (_currentPage == 1) {
        _properties = newProperties;
      } else {
        _properties.addAll(newProperties);
      }
      
      _currentPage = (pagination['page'] as int? ?? 1) + 1;
      _totalPages = pagination['pages'] as int? ?? 1;
      _hasMoreData = _currentPage <= _totalPages;
      
      // Update filters
      _cityFilter = city ?? _cityFilter;
      _minPriceFilter = minPrice ?? _minPriceFilter;
      _maxPriceFilter = maxPrice ?? _maxPriceFilter;
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur fetchProperties: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProperties() async {
    if (!_hasMoreData || _isLoading) return;
    
    await fetchProperties(
      city: _cityFilter,
      minPrice: _minPriceFilter,
      maxPrice: _maxPriceFilter,
    );
  }

  Future<void> refreshProperties() async {
    await fetchProperties(
      refresh: true,
      city: _cityFilter,
      minPrice: _minPriceFilter,
      maxPrice: _maxPriceFilter,
    );
  }

  void applyFilters({
    String? city,
    double? minPrice,
    double? maxPrice,
  }) {
    _cityFilter = city;
    _minPriceFilter = minPrice;
    _maxPriceFilter = maxPrice;
    
    fetchProperties(refresh: true, city: city, minPrice: minPrice, maxPrice: maxPrice);
  }

  void clearFilters() {
    _cityFilter = null;
    _minPriceFilter = null;
    _maxPriceFilter = null;
    _filteredProperties.clear();
    
    fetchProperties(refresh: true);
  }

  void searchProperties(String query) {
    if (query.isEmpty) {
      _filteredProperties.clear();
    } else {
      _filteredProperties = _properties.where((property) {
        return property.title.toLowerCase().contains(query.toLowerCase()) ||
               property.city.toLowerCase().contains(query.toLowerCase()) ||
               (property.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addProperty(Map<String, dynamic> propertyData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.addProperty(propertyData);
      
      // Refresh the list to include the new property
      await fetchProperties(refresh: true);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur addProperty: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.updateProperty(id, data);
      
      // Update local list
      final index = _properties.indexWhere((p) => p.id == id);
      if (index != -1) {
        await fetchProperties(refresh: true);
      }
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur updateProperty: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.deleteProperty(id);
      
      // Remove from local list
      _properties.removeWhere((p) => p.id == id);
      _filteredProperties.removeWhere((p) => p.id == id);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur deleteProperty: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Property? getPropertyById(String id) {
    try {
      return _properties.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}