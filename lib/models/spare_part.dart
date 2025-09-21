import 'dart:convert';

enum SparePartCondition {
  brandNew,
  usedLikeNew,
  usedGood,
  forParts,
  other,
}

class SparePart {
  final String id;
  final List<String> mediaUrls;
  final String ownerId;
  final String title;
  final String description;
  final SparePartCondition condition;
  final double price;
  final String contact;
  final String location;
  final DateTime createdAt;

  SparePart({
    required this.id,
    required this.mediaUrls,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.condition,
    required this.price,
    required this.contact,
    required this.location,
    required this.createdAt,
  });

  /// Creates a SparePart object from a Supabase record (Map).
  factory SparePart.fromMap(Map<String, dynamic> map) {
    return SparePart(
      id: map['id'] as String,
      mediaUrls: List<String>.from(map['media_urls'] as List),
      ownerId: map['owner_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      condition: SparePartCondition.values.byName(map['condition'] as String),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      contact: map['contact'] as String,
      location: map['location'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts a SparePart object into a Map for inserting or updating in Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'media_urls': mediaUrls,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'condition': condition.name,
      'price': price,
      'contact': contact,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => json.encode(toMap());

  factory SparePart.fromJson(String source) =>
      SparePart.fromMap(json.decode(source) as Map<String, dynamic>);
}