import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://192.168.100.136:3000';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cache pour les requêtes GET
  final Map<String, Map<String, dynamic>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Client HTTP réutilisable avec connexion persistante
  late final http.Client _client = http.Client();

  Map<String, String> _jsonHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Connection': 'keep-alive',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Utilisateur non authentifié");
    return token;
  }

  // Méthode de retry avec backoff exponentiel
  Future<T> _retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await request();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        if (e is SocketException || e is HttpException) {
          // Attendre avant de réessayer
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        } else {
          rethrow;
        }
      }
    }
    throw Exception('Échec après $maxRetries tentatives');
  }

  // Cache helper
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  void _setCacheData(String key, Map<String, dynamic> data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  Map<String, dynamic>? _getCacheData(String key) {
    if (_isCacheValid(key)) {
      return _cache[key];
    }
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return _retryRequest(() async {
      final url = Uri.parse('$baseUrl/auth/login');
      final res = await _client.post(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString('token', data['token']),
          prefs.setString('role', data['role']),
          prefs.setString('userId', data['userId']),
          prefs.setString('userName', data['userName'] ?? 'Utilisateur'),
        ]);
        return data;
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur de connexion');
      }
    });
  }

  Future<Map<String, dynamic>> register(String email, String password, String role) async {
    return _retryRequest(() async {
      final url = Uri.parse('$baseUrl/auth/register');
      final res = await _client.post(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur d\'inscription');
      }
    });
  }

  Future<Map<String, dynamic>> getProperties({
    String? city,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 10,
    bool useCache = true,
  }) async {
    final cacheKey = 'properties_${city ?? ''}_${minPrice ?? ''}_${maxPrice ?? ''}_${page}_$limit';
    
    if (useCache) {
      final cachedData = _getCacheData(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    return _retryRequest(() async {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

      final uri = Uri.parse('$baseUrl/properties').replace(queryParameters: queryParams);
      final res = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=300',
        }
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (useCache) {
          _setCacheData(cacheKey, data);
        }
        return data;
      } else {
        throw Exception("Erreur chargement : ${res.statusCode}");
      }
    });
  }

  Future<void> addProperty(Map<String, dynamic> property) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/properties');
      final res = await _client.post(
        url,
        headers: _jsonHeaders(token),
        body: jsonEncode(property),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode != 201) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Échec de l\'ajout');
      }

      // Invalider le cache des propriétés
      _cache.removeWhere((key, value) => key.startsWith('properties_'));
      _cacheTimestamps.removeWhere((key, value) => key.startsWith('properties_'));
    });
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/properties/$id');
      final res = await _client.put(
        url,
        headers: _jsonHeaders(token),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur de modification');
      }

      // Invalider le cache
      _cache.removeWhere((key, value) => key.startsWith('properties_') || key.contains(id));
      _cacheTimestamps.removeWhere((key, value) => key.startsWith('properties_') || key.contains(id));
    });
  }

  Future<void> deleteProperty(String id) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/properties/$id');
      final res = await _client.delete(
        url,
        headers: _jsonHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur de suppression');
      }

      // Invalider le cache
      _cache.removeWhere((key, value) => key.startsWith('properties_') || key.contains(id));
      _cacheTimestamps.removeWhere((key, value) => key.startsWith('properties_') || key.contains(id));
    });
  }

  Future<void> createBooking(
    String propertyId,
    String propertyTitle,
    String message,
    String ownerId,
  ) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final prefs = await SharedPreferences.getInstance();
      final renterId = prefs.getString('userId');
      final renterName = prefs.getString('userName');

      final url = Uri.parse('$baseUrl/bookings');
      final res = await _client.post(
        url,
        headers: _jsonHeaders(token),
        body: jsonEncode({
          "propertyId": propertyId,
          "propertyTitle": propertyTitle,
          "renterId": renterId,
          "renterName": renterName,
          "ownerId": ownerId,
          "message": message,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 201) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur réservation');
      }
    });
  }

  Future<List<dynamic>> getBookingsForOwner() async {
    return _retryRequest(() async {
      final token = await _getToken();
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getString('userId');
      final url = Uri.parse('$baseUrl/bookings/owner/$ownerId');

      final res = await _client.get(
        url,
        headers: _jsonHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur chargement');
      }
    });
  }

  Future<List<dynamic>> getMyBookings() async {
    return _retryRequest(() async {
      final token = await _getToken();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final url = Uri.parse('$baseUrl/bookings/$userId');

      final res = await _client.get(
        url,
        headers: _jsonHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur chargement');
      }
    });
  }

  Future<List<dynamic>> getUsers() async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/admin/users');
      final res = await _client.get(
        url,
        headers: _jsonHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur inconnue');
      }
    });
  }

  Future<void> deleteUser(String userId) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/admin/users/$userId');
      final res = await _client.delete(url, headers: _jsonHeaders(token));
      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur suppression utilisateur');
      }
    });
  }

  Future<void> deletePropertyAsAdmin(String id) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/admin/properties/$id');
      final res = await _client.delete(url, headers: _jsonHeaders(token));
      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur suppression propriété');
      }
    });
  }

  Future<void> updatePropertyAsAdmin(String id, Map<String, dynamic> data) async {
    return _retryRequest(() async {
      final token = await _getToken();
      final url = Uri.parse('$baseUrl/admin/properties/$id');
      final res = await _client.put(
        url,
        headers: _jsonHeaders(token),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur de mise à jour');
      }
    });
  }

  Future<Map<String, dynamic>> getPropertyById(String id) async {
    final cacheKey = 'property_$id';
    
    final cachedData = _getCacheData(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }

    return _retryRequest(() async {
      final url = Uri.parse('$baseUrl/properties/$id');
      final res = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=600',
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _setCacheData(cacheKey, data);
        return data;
      } else {
        throw Exception("Impossible de récupérer le bien");
      }
    });
  }

  // Méthode de nettoyage
  void dispose() {
    _client.close();
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Méthode pour vider le cache manuellement
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
