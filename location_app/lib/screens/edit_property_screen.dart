import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditPropertyScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const EditPropertyScreen({Key? key, required this.property}) : super(key: key);

  @override
  _EditPropertyScreenState createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property['title']);
    _locationController = TextEditingController(text: widget.property['location']);
    _descriptionController = TextEditingController(text: widget.property['description']);
    _priceController = TextEditingController(text: widget.property['price']?.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedData = {
      'title': _titleController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': int.tryParse(_priceController.text.trim()) ?? 0,
    };

    try {
      final id = widget.property['_id'];
      await apiService.updateProperty(id, updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bien mis à jour avec succès')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifier le bien')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Titre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Localisation'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Prix (FCFA)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitUpdate,
                icon: Icon(Icons.save),
                label: Text('Enregistrer les modifications'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
