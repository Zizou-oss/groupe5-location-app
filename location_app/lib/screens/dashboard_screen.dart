import 'package:flutter/material.dart';
import 'package:location_app/screens/add_property_screen.dart';
import 'package:location_app/screens/owner_bookings_screen.dart';
import 'package:location_app/screens/property_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> properties = [];
  bool isLoading = true;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? '';

    try {
      final all = await apiService.getProperties();
      setState(() {
        properties = all.where((p) => p['ownerId'] == userId).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord propriétaire'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OwnerBookingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPropertyScreen()),
        ),
        icon: Icon(Icons.add),
        label: Text("Ajouter un bien"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : properties.isEmpty
              ? Center(child: Text("Aucune propriété trouvée"))
              : ListView.builder(
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final prop = properties[index];
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PropertyDetailScreen(propertyId: prop['_id']),
                          ),
                        );

                        if (result == true) {
                          // Recharge les données quand on revient
                          _loadProperties();
                        }
                      },

                      child: Card(
                        margin:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (prop['images'] != null &&
                                prop['images'].isNotEmpty &&
                                prop['images'][0] != null &&
                                prop['images'][0].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15)),
                                child: Image.network(
                                  prop['images'][0],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(15)),
                                ),
                                child:
                                    Icon(Icons.image_not_supported, size: 50),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prop['title'] ?? 'Sans titre',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text(prop['location'] ?? 'Lieu inconnu',
                                      style:
                                          TextStyle(color: Colors.grey[700])),
                                  SizedBox(height: 4),
                                  Text('${prop['price'] ?? 0} FCFA',
                                      style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500)),
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
