class Booking {
  final String id;
  final String propertyTitle;
  final String renterId;
  final String renterName;
  final String ownerId;
  String status; // pending, accepted, rejected
  final String message;
  final DateTime createdAt;
  
  Booking({
    required this.id,
    required this.propertyTitle,
    required this.renterId,
    required this.renterName,
    required this.ownerId,
    this.status = "pending",
    this.message = "",
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();
}
