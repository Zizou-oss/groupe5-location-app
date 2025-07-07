import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://192.168.100.136:3000';

class ApiService {
  Map<String, String> _jsonHeaders([String? token]) {
    final headers = {'Content-Type': 'application/json'};
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

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);
      await prefs.setString('userId', data['userId']);
      await prefs.setString('userName', data['userName'] ?? 'Utilisateur');
      return data;
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur de connexion');
    }
  }

  Future<Map<String, dynamic>> register(
      String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final res = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur d’inscription');
    }
  }

  Future<List<dynamic>> getProperties() async {
    final url = Uri.parse('$baseUrl/properties');
    final res = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    }).timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Erreur chargement : ${res.statusCode}");
    }
  }

  Future<void> addProperty(Map<String, dynamic> property) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/properties');
    final res = await http.post(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode(property),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode != 201) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Échec de l’ajout');
    }
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/properties/$id');
    final res = await http.put(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode(data),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur de modification');
    }
  }

  Future<void> deleteProperty(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/properties/$id');
    final res = await http.delete(
      url,
      headers: _jsonHeaders(token),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur de suppression');
    }
  }

  Future<void> createBooking(
    String propertyId,
    String propertyTitle,
    String message,
    String ownerId,
  ) async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final renterId = prefs.getString('userId');
    final renterName = prefs.getString('userName');

    final url = Uri.parse('$baseUrl/bookings');
    final res = await http.post(
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
    ).timeout(Duration(seconds: 10));

    if (res.statusCode != 201) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur réservation');
    }
  }

  Future<List<dynamic>> getBookingsForOwner() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getString('userId');
    final url = Uri.parse('$baseUrl/bookings/owner/$ownerId');

    final res = await http.get(
      url,
      headers: _jsonHeaders(token),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur chargement');
    }
  }

  Future<List<dynamic>> getMyBookings() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final url = Uri.parse('$baseUrl/bookings/$userId');

    final res = await http.get(
      url,
      headers: _jsonHeaders(token),
    ).timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur chargement');
    }
  }

  Future<List<dynamic>> getUsers() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/users');
    final res = await http.get(
      url,
      headers: _jsonHeaders(token),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur inconnue');
    }
  }

  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/users/$userId');
    final res = await http.delete(url, headers: _jsonHeaders(token));
    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur suppression utilisateur');
    }
  }

  Future<void> deletePropertyAsAdmin(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/properties/$id');
    final res = await http.delete(url, headers: _jsonHeaders(token));
    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur suppression propriété');
    }
  }

  

  Future<void> updatePropertyAsAdmin(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/properties/$id');
    final res = await http.put(
      url,
      headers: _jsonHeaders(token),
      body: jsonEncode(data),
    );
    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur de mise à jour');
    }
  }

  Future<Map<String, dynamic>> getPropertyById(String id) async {
    final url = Uri.parse('$baseUrl/properties/$id');
    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    ).timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Impossible de récupérer le bien");
    }
  }
}
