import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerBookingsScreen extends StatefulWidget {
  @override
  _OwnerBookingsScreenState createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  final ApiService apiService = ApiService();
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final result = await apiService.getBookingsForOwner();
      setState(() {
        bookings = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réservations reçues")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(child: Text("Aucune réservation reçue."))
              : ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      child: ListTile(
                        title: Text(booking['propertyTitle'] ?? 'Maison'),
                        subtitle: Text(
                          "Demande par : ${booking['renterName']}\nMessage : ${booking['message']}",
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
