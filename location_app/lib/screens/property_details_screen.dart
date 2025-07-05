import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'booking_request_screen.dart';
import 'edit_property_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({Key? key, required this.propertyId}) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? property;
  bool isLoading = true;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    print("🔎 Chargement du bien avec ID : ${widget.propertyId}");
    try {
      final data = await apiService.getPropertyById(widget.propertyId);
      print("✅ Données reçues : $data");

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      setState(() {
        property = data;
        isOwner = data['ownerId'] == userId;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Erreur de chargement du bien : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _deleteProperty() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Supprimer ce bien"),
        content: Text("Êtes-vous sûr de vouloir supprimer ce bien ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Supprimer")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await apiService.deleteProperty(widget.propertyId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bien supprimé avec succès")));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || property == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Chargement...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final images = property!['images'] ?? [];
    final features = property!['features'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(property!['title'] ?? 'Détail du bien')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Image.network(images[0], height: 250, width: double.infinity, fit: BoxFit.cover)
            else
              Container(
                height: 250,
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.image_not_supported, size: 50)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property!['title'] ?? 'Sans titre', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[700]),
                      SizedBox(width: 4),
                      Text(property!['location'] ?? 'Non précisé', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text("${property!['price'] ?? '0'} FCFA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[700])),
                  SizedBox(height: 16),
                  Text(property!['description'] ?? 'Pas de description', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  if (features.isNotEmpty) ...[
                    Text("Équipements", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(features.length, (index) {
                        return Chip(label: Text(features[index]), backgroundColor: Colors.blue.shade100);
                      }),
                    ),
                  ],
                  SizedBox(height: 20),
                  if (isOwner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPropertyScreen(property: property!),
                              ),
                            );
                            if (result == true) {
                              _loadProperty();
                              Navigator.pop(context, true);
                            }
                          },
                          icon: Icon(Icons.edit),
                          label: Text("Modifier"),
                        ),
                        ElevatedButton.icon(
                          onPressed: _deleteProperty,
                          icon: Icon(Icons.delete),
                          label: Text("Supprimer"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingRequestScreen(property: property!),
                            ),
                          );
                        },
                        icon: Icon(Icons.send),
                        label: Text("Faire une demande"),
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
