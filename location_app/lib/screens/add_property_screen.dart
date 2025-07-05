import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddPropertyScreen extends StatefulWidget {
  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String city = '';
  int price = 0;
  int size = 0;
  String featuresRaw = '';
  bool loading = false;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => loading = true);

    try {
      final newProperty = {
        "title": title,
        "city": city,
        "price": price,
        "size": size,
        "features": featuresRaw.split(',').map((e) => e.trim()).toList(),
      };

      await ApiService().addProperty(newProperty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Maison ajoutée avec succès")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une maison")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: "Titre"),
                onSaved: (val) => title = val!.trim(),
                validator: (val) => val!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Ville"),
                onSaved: (val) => city = val!.trim(),
                validator: (val) => val!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Prix"),
                keyboardType: TextInputType.number,
                onSaved: (val) => price = int.parse(val!),
                validator: (val) => val!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Taille (m²)"),
                keyboardType: TextInputType.number,
                onSaved: (val) => size = int.parse(val!),
                validator: (val) => val!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                decoration: InputDecoration(
                    labelText: "Caractéristiques (séparées par des virgules)"),
                onSaved: (val) => featuresRaw = val ?? '',
              ),
              SizedBox(height: 20),
              loading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text("Ajouter la maison"),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
