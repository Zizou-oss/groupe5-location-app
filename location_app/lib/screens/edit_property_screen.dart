import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../services/api_service.dart' show baseUrl;

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
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  List<XFile> _newImages = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property['title']);
    _locationController = TextEditingController(text: widget.property['city']);
    _descriptionController = TextEditingController(text: widget.property['description'] ?? '');
    _priceController = TextEditingController(text: widget.property['price']?.toString() ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? picked = await picker.pickMultiImage();

    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _newImages = picked;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final propertyId = widget.property['_id'];

    var uri = Uri.parse("$baseUrl/properties/$propertyId");

    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = _titleController.text.trim();
    request.fields['city'] = _locationController.text.trim();
    request.fields['description'] = _descriptionController.text.trim();
    request.fields['price'] = _priceController.text.trim();

    // Si des images ont été ajoutées, on les envoie (et côté backend elles écrasent les anciennes)
    for (var image in _newImages) {
      var file = File(image.path);
      var mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      var split = mimeType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        file.path,
        contentType: MediaType(split[0], split[1]),
        filename: basename(file.path),
      ));
    }

    try {
      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text("Propriété modifiée avec succès")),
        );
        Navigator.pop(this.context, true);
      } else {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text("Erreur ${response.statusCode} : $body")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() => _loading = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _newImages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('Modifier la propriété')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: 'Titre'),
                        validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(labelText: 'Ville'),
                        validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                      ),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(labelText: 'Prix'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.image),
                        label: Text('Ajouter de nouvelles images'),
                      ),
                      SizedBox(height: 10),
                      hasImages
                          ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _newImages.map((img) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(img.path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }).toList(),
                            )
                          : Text("Aucune nouvelle image sélectionnée."),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitUpdate,
                        child: Text('Enregistrer les modifications'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
