import 'package:flutter/material.dart';

class Booking {
  final String id;
  final String propertyTitle;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  Booking({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.startDate,
    required this.endDate,
  });
}

class MyBookingsScreen extends StatefulWidget {
  @override
  _MyBookingsScreenState createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    // Simulé, plus tard via API
    setState(() {
      _bookings = [
        Booking(
          id: 'b1',
          propertyTitle: 'Villa moderne',
          status: 'En attente',
          startDate: DateTime.now().add(Duration(days: 3)),
          endDate: DateTime.now().add(Duration(days: 10)),
        ),
        Booking(
          id: 'b2',
          propertyTitle: 'Appartement meublé',
          status: 'Acceptée',
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().subtract(Duration(days: 10)),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes demandes")),
      body: _bookings.isEmpty
          ? Center(child: Text("Aucune demande pour le moment"))
          : ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    title: Text(booking.propertyTitle),
                    subtitle: Text(
                        "Du ${booking.startDate.toLocal().toString().split(' ')[0]} au ${booking.endDate.toLocal().toString().split(' ')[0]}"),
                    trailing: Text(
                      booking.status,
                      style: TextStyle(
                        color: booking.status == 'Acceptée'
                            ? Colors.green
                            : (booking.status == 'Refusée' ? Colors.red : Colors.orange),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
