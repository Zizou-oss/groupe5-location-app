import 'package:flutter/material.dart';
import 'package:location_app/screens/property_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> properties = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final list = await apiService.getProperties();
      setState(() {
        properties = list;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des propriétés")),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biens disponibles'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Se déconnecter",
            onPressed: _logout,
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? Center(child: Text('Aucune propriété disponible.'))
              : ListView.builder(
                  itemCount: properties.length,
                  padding: EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(propertyId: prop['_id']),
                            ),
                          );
                          if (result == true) {
                            _fetchProperties();
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                              child: prop['images'] != null && prop['images'].isNotEmpty
                                  ? Image.network(
                                      prop['images'][0],
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 180,
                                      color: Colors.grey[300],
                                      child: Center(child: Icon(Icons.image, size: 60, color: Colors.grey[600])),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prop['title'] ?? 'Sans titre',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    prop['location'] ?? 'Ville inconnue',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${prop['price']?.toString() ?? 'N/A'} FCFA / mois',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
