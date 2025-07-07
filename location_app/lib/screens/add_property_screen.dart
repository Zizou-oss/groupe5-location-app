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

class CreatePropertyScreen extends StatefulWidget {
  @override
  _CreatePropertyScreenState createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<XFile> _images = [];
  bool _loading = false;
  bool _isPickingImages = false; // ✅ Nouveau flag pour éviter les doubles appels
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    // ✅ Empêcher les appels multiples
    if (_isPickingImages) return;
    
    setState(() {
      _isPickingImages = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? picked = await picker.pickMultiImage();

      if (picked != null && picked.isNotEmpty) {
        setState(() {
          _images = picked;
        });
      }
    } catch (e) {
      // ✅ Gestion des erreurs
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la sélection d'images: $e"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      // ✅ Réinitialiser le flag dans tous les cas
      setState(() {
        _isPickingImages = false;
      });
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text("Veuillez ajouter au moins une image."),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var uri = Uri.parse("$baseUrl/properties");

    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = _titleController.text;
    request.fields['city'] = _cityController.text;
    request.fields['price'] = _priceController.text;
    request.fields['size'] = _sizeController.text;
    request.fields['description'] = _descriptionController.text;

    for (var image in _images) {
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
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text("Maison ajoutée avec succès !"),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(this.context, true);
      } else {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text("Erreur ${response.statusCode}: $responseBody"),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text("Erreur : $e"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF667eea)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        fillColor: Color(0xFFF5F6FA),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF6B73FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec icône de retour
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouvelle Propriété',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Ajoutez votre bien immobilier',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Icône de propriété
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.home_work,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenu principal
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Création en cours...',
                                style: TextStyle(
                                  color: Color(0xFF667eea),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Informations de base
                                    Text(
                                      'Informations de base',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    
                                    _buildTextField(
                                      controller: _titleController,
                                      label: 'Titre de la propriété',
                                      hint: 'ex: Villa moderne à Ouaga 2000',
                                      icon: Icons.title,
                                      validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                                    ),
                                    SizedBox(height: 16),
                                    
                                    _buildTextField(
                                      controller: _cityController,
                                      label: 'Ville',
                                      hint: 'ex: Ouagadougou, Bobo-Dioulasso, Koudougou',
                                      icon: Icons.location_city,
                                      validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                                    ),
                                    SizedBox(height: 16),
                                    
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _priceController,
                                            label: 'Prix (FCFA)',
                                            hint: 'ex: 25000000',
                                            icon: Icons.monetization_on,
                                            keyboardType: TextInputType.number,
                                            validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _sizeController,
                                            label: 'Taille (m²)',
                                            hint: 'ex: 120',
                                            icon: Icons.square_foot,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Champ Description
                                    TextFormField(
                                      controller: _descriptionController,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        labelText: 'Description',
                                        hintText: 'ex: Belle villa située dans le quartier résidentiel de Ouaga 2000, comprenant 4 chambres, 3 salles de bains, salon spacieux avec carrelage, cuisine moderne équipée, garage pour 2 voitures, jardin arboré, sécurisé 24h/24...',
                                        prefixIcon: Padding(
                                          padding: EdgeInsets.only(bottom: 60),
                                          child: Icon(Icons.description, color: Color(0xFF667eea)),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide.none,
                                        ),
                                        fillColor: Color(0xFFF5F6FA),
                                        filled: true,
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                                    ),
                                    SizedBox(height: 30),
                                    
                                    // Section Images
                                    Text(
                                      'Photos de la propriété',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Bouton d'ajout d'images
                                    GestureDetector(
                                      onTap: _pickImages,
                                      child: Container(
                                        width: double.infinity,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF5F6FA),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(
                                            color: Color(0xFF667eea).withOpacity(0.3),
                                            width: 2,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 40,
                                              color: Color(0xFF667eea),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Ajouter des photos',
                                              style: TextStyle(
                                                color: Color(0xFF667eea),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Touchez pour sélectionner',
                                              style: TextStyle(
                                                color: Color(0xFF667eea).withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Aperçu des images
                                    if (_images.isNotEmpty) ...[
                                      Text(
                                        '${_images.length} image(s) sélectionnée(s)',
                                        style: TextStyle(
                                          color: Color(0xFF667eea),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _images.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              margin: EdgeInsets.only(right: 12),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.file(
                                                      File(_images[index].path),
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _images.removeAt(index);
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red.withOpacity(0.8),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(
                                                          Icons.close,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ] else
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.grey.shade600),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Aucune image sélectionnée. Ajoutez au moins une photo.',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    SizedBox(height: 40),
                                    
                                    // Bouton de soumission
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        onPressed: _submitProperty,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF667eea),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          elevation: 5,
                                          shadowColor: Color(0xFF667eea).withOpacity(0.4),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_home, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Créer la propriété',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}