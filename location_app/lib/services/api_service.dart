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
    final res = await http
        .post(
          url,
          headers: _jsonHeaders(),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(Duration(seconds: 10));

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
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final res = await http
        .post(
          url,
          headers: _jsonHeaders(),
          body: jsonEncode({
            'email': email,
            'password': password,
            'role': role,
          }),
        )
        .timeout(Duration(seconds: 10));

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur d’inscription');
    }
  }

  Future<List<dynamic>> getProperties() async {
    final url = Uri.parse('$baseUrl/properties');

    print("📡 Envoi requête à : $url");

    try {
      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
          )
          .timeout(Duration(seconds: 10));

      print("⬅️ Code HTTP : ${res.statusCode}");
      print("⬅️ Réponse body : ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Erreur chargement : ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      print("❌ Exception HTTP : $e");
      rethrow;
    }
  }

  Future<void> addProperty(Map<String, dynamic> property) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/properties');

    final res = await http
        .post(url, headers: _jsonHeaders(token), body: jsonEncode(property))
        .timeout(Duration(seconds: 10));

    if (res.statusCode != 201) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Échec de l’ajout de propriété');
    }
  }

  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/properties/$id');

    final res = await http
        .put(url, headers: _jsonHeaders(token), body: jsonEncode(data))
        .timeout(Duration(seconds: 10));

    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur de modification');
    }
  }

  Future<List<dynamic>> getUsers() async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/users');

    print("📡 Appel API : $url");
    try {
      final res = await http.get(url, headers: _jsonHeaders(token));
      print("⬅️ Status code: ${res.statusCode}");
      print("⬅️ Body: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        final error = jsonDecode(res.body);
        throw Exception(error['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      print("❌ Erreur dans getUsers: $e");
      rethrow;
    }
  }

  // Supprimer un utilisateur (admin)
  Future<void> deleteUser(String userId) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/users/$userId');

    final res = await http.delete(url, headers: _jsonHeaders(token));
    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur suppression utilisateur');
    }
  }

  Future<void> deleteProperty(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/properties/$id');

    final res = await http
        .delete(url, headers: _jsonHeaders(token))
        .timeout(Duration(seconds: 10));

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

    if (renterId == null || renterName == null) {
      throw Exception("Données utilisateur manquantes");
    }

    final url = Uri.parse('$baseUrl/bookings');
    final res = await http
        .post(
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
        )
        .timeout(Duration(seconds: 10));

    if (res.statusCode != 201) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur lors de la réservation');
    }
  }

  Future<List<dynamic>> getBookingsForOwner() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getString('userId');

    if (ownerId == null) throw Exception("ID utilisateur manquant");

    final url = Uri.parse('$baseUrl/bookings/owner/$ownerId');
    final res = await http
        .get(url, headers: _jsonHeaders(token))
        .timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur lors du chargement');
    }
  }

  Future<List<dynamic>> getMyBookings() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) throw Exception("ID utilisateur manquant");

    final url = Uri.parse('$baseUrl/bookings/$userId');
    final res = await http
        .get(url, headers: _jsonHeaders(token))
        .timeout(Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur lors du chargement');
    }
  }

  // ✅ Supprimer une propriété (admin)
  Future<void> deletePropertyAsAdmin(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$baseUrl/admin/properties/$id');

    final res = await http.delete(url, headers: _jsonHeaders(token));
    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw Exception(error['message'] ?? 'Erreur suppression propriété');
    }
  }

  // ✅ Modifier une propriété (admin)
  Future<void> updatePropertyAsAdmin(
    String id,
    Map<String, dynamic> data,
  ) async {
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
    print("➡️ Requête GET : $url");

    final res = await http
        .get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        )
        .timeout(Duration(seconds: 10));

    print("⬅️ Code : ${res.statusCode}");
    print("⬅️ Body : ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Impossible de récupérer le bien");
    }
  }
}
