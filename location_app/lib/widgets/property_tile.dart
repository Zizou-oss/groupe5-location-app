import 'package:flutter/material.dart';
import '../models/property.dart';

class PropertyTile extends StatelessWidget {
  final Property property;
  const PropertyTile({required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(property.title),
        subtitle: Text("${property.city} - ${property.price} FCFA"),
        trailing: Text("${property.size} m²"),
      ),
    );
  }
}
