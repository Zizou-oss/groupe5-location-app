class Property {
  final String id;
  final String title;
  final String city;
  final double price;
  final String? size;
  final String? description;
  final List<String> features;
  final List<String> images;
  final String ownerId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? imageCount;

  const Property({
    required this.id,
    required this.title,
    required this.city,
    required this.price,
    this.size,
    this.description,
    this.features = const [],
    this.images = const [],
    required this.ownerId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.imageCount,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      price: (json['price'] as num).toDouble(),
      size: json['size'] as String?,
      description: json['description'] as String?,
      features: List<String>.from(json['features'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      ownerId: json['ownerId'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageCount: json['imageCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'city': city,
      'price': price,
      'size': size,
      'description': description,
      'features': features,
      'images': images,
      'ownerId': ownerId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageCount': imageCount,
    };
  }

  Property copyWith({
    String? id,
    String? title,
    String? city,
    double? price,
    String? size,
    String? description,
    List<String>? features,
    List<String>? images,
    String? ownerId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? imageCount,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      price: price ?? this.price,
      size: size ?? this.size,
      description: description ?? this.description,
      features: features ?? this.features,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageCount: imageCount ?? this.imageCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Property && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Property(id: $id, title: $title, city: $city, price: $price)';
  }
}
