import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_bookings.dart'; // la liste globale
import '../models/booking.dart';

class ReservationRequestsScreen extends StatefulWidget {
  @override
  _ReservationRequestsScreenState createState() => _ReservationRequestsScreenState();
}

class _ReservationRequestsScreenState extends State<ReservationRequestsScreen> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId'); // ex: "bailleur123"
    });
  }

  void _updateBookingStatus(Booking booking, String newStatus) {
    setState(() {
      booking.status = newStatus;
    });
  }

  Widget _buildBookingCard(Booking booking) {
    Color statusColor;
    switch (booking.status) {
      case "accepted":
        statusColor = Colors.green;
        break;
      case "rejected":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(Icons.person, color: Colors.blue),
        title: Text("${booking.renterName} souhaite réserver ${booking.propertyTitle}"),
        subtitle: Text(booking.message),
        trailing: booking.status == "pending"
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _updateBookingStatus(booking, "accepted"),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _updateBookingStatus(booking, "rejected"),
                  ),
                ],
              )
            : Text(
                booking.status.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myBookings = mockBookings
        .where((b) => b.ownerId == currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Demandes de réservation")),
      body: currentUserId == null
          ? Center(child: CircularProgressIndicator())
          : myBookings.isEmpty
              ? Center(child: Text("Aucune demande reçue"))
              : ListView.builder(
                  itemCount: myBookings.length,
                  itemBuilder: (context, index) =>
                      _buildBookingCard(myBookings[index]),
                ),
    );
  }
}
