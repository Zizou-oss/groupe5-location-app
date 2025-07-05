import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_app/screens/login_screen.dart';
import 'package:location_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  List<dynamic> properties = [];
  List<dynamic> users = [];
  bool isLoadingProperties = true;
  bool isLoadingUsers = true;
  String adminName = 'Admin';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
    _loadProperties();
    _loadUsers();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminName = prefs.getString('userName') ?? 'Admin';
    });
  }

  Future<void> _loadProperties() async {
    setState(() => isLoadingProperties = true);
    try {
      final data = await ApiService().getProperties();
      setState(() {
        properties = data;
        isLoadingProperties = false;
      });
    } catch (e) {
      setState(() => isLoadingProperties = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des propriétés")),
      );
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoadingUsers = true);
    try {
      final data = await ApiService().getUsers();
      setState(() {
        users = data;
        isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des utilisateurs")),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await ApiService().deleteUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Utilisateur supprimé")),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la suppression")),
      );
    }
  }

  Future<void> _deleteProperty(String id) async {
    try {
      await ApiService().deletePropertyAsAdmin(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Maison supprimée")),
      );
      _loadProperties();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur suppression propriété : $e")),
      );
    }
  }

  Future<void> _editProperty(Map<String, dynamic> prop) async {
    final titleController = TextEditingController(text: prop['title']);
    final cityController = TextEditingController(text: prop['city']);
    final priceController = TextEditingController(text: prop['price'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Modifier la maison'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: 'Titre')),
              TextField(controller: cityController, decoration: InputDecoration(labelText: 'Ville')),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final city = cityController.text.trim();
              final price = int.tryParse(priceController.text.trim()) ?? 0;

              if (title.isEmpty || city.isEmpty || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Tous les champs sont obligatoires")),
                );
                return;
              }

              try {
                await ApiService().updatePropertyAsAdmin(prop['_id'], {
                  'title': title,
                  'city': city,
                  'price': price,
                });
                Navigator.pop(context);
                _loadProperties();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Maison mise à jour")),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur de mise à jour : $e")),
                );
              }
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel - $adminName"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Déconnexion",
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Propriétés"),
            Tab(text: "Utilisateurs"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          isLoadingProperties
              ? Center(child: CircularProgressIndicator())
              : properties.isEmpty
                  ? Center(child: Text("Aucune propriété enregistrée."))
                  : ListView.builder(
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final prop = properties[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: ListTile(
                            leading: Icon(Icons.home),
                            title: Text(prop['title'] ?? 'Sans titre'),
                            subtitle: Text("${prop['city']} - ${prop['price']} FCFA"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editProperty(prop),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Confirmer la suppression'),
                                      content: Text('Supprimer cette maison ?'),
                                      actions: [
                                        TextButton(
                                          child: Text('Annuler'),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                        TextButton(
                                          child: Text('Supprimer'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteProperty(prop['_id']);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          isLoadingUsers
              ? Center(child: CircularProgressIndicator())
              : users.isEmpty
                  ? Center(child: Text("Aucun utilisateur trouvé."))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: ListTile(
                            title: Text(user['email']),
                            subtitle: Text("Rôle : ${user['role']}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text('Confirmer la suppression'),
                                  content: Text('Supprimer ${user['email']} ?'),
                                  actions: [
                                    TextButton(
                                      child: Text('Annuler'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    TextButton(
                                      child: Text('Supprimer'),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteUser(user['_id']);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
