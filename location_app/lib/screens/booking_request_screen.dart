import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking.dart';
import '../data/mock_bookings.dart';

class BookingRequestScreen extends StatefulWidget {
  final Map<String, dynamic> property;

  const BookingRequestScreen({Key? key, required this.property}) : super(key: key);

  @override
  _BookingRequestScreenState createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _message = '';
  bool _isSubmitting = false;

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final renterId = prefs.getString('userId') ?? '';
    final renterName = prefs.getString('userName') ?? 'Locataire';
    final ownerId = widget.property['ownerId'];

    final newBooking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      propertyTitle: widget.property['title'],
      renterId: renterId,
      renterName: renterName,
      ownerId: ownerId,
      status: 'pending',
      message: _message,
      createdAt: DateTime.now(),
    );

    mockBookings.add(newBooking);
    await Future.delayed(Duration(seconds: 1));

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Demande envoyée avec succès')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Demande de réservation")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                "Envoyer une demande pour : ${widget.property['title']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Message au bailleur",
                  border: OutlineInputBorder(),
                  hintText: "Écrivez votre message ici",
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Veuillez entrer un message'
                    : null,
                onSaved: (val) => _message = val!.trim(),
              ),
              SizedBox(height: 24),
              _isSubmitting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitBooking,
                      child: Text("Envoyer la demande"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
