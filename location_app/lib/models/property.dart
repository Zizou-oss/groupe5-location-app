class Property {
  final String id;
  final String title;
  final String city;
  final int price;
  final int size;
  final List<String> features;
  final String ownerId;

  Property({
    required this.id,
    required this.title,
    required this.city,
    required this.price,
    required this.size,
    required this.features,
    required this.ownerId,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'],
      title: json['title'],
      city: json['city'],
      price: json['price'],
      size: json['size'],
      features: List<String>.from(json['features'] ?? []),
      ownerId: json['ownerId'],
    );
  }
}
