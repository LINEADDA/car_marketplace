class RepairShop {
  final String id;
  final List<String> mediaUrls;
  final String ownerId;
  final String name;
  final String services;
  final String pricingInfo;
  final String location;
  final String contactNumber;
  final DateTime createdAt;

  RepairShop({
    required this.id,
    required this.mediaUrls,
    required this.ownerId,
    required this.name,
    required this.services,
    required this.pricingInfo,
    required this.location,
    required this.contactNumber,
    required this.createdAt,
  });

  /// Creates a RepairShop object from a Supabase record (Map).
  /// This correctly handles the conversion of database types to Dart types.
  factory RepairShop.fromMap(Map<String, dynamic> map) {
    return RepairShop(
      id: map['id'] as String,
      mediaUrls: List<String>.from(map['media_urls'] as List),
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      services: map['services'] as String,
      pricingInfo: map['pricing_info'] as String,
      location: map['location'] as String,
      contactNumber: map['contact_number'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts a RepairShop object into a Map for inserting or updating in Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'media_urls': mediaUrls,
      'owner_id': ownerId,
      'name': name,
      'services': services,
      'pricing_info': pricingInfo,
      'location': location,
      'contact_number': contactNumber,
      'created_at': createdAt.toIso8601String(),
    };
  }
}