import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart'; 

class RepairShop {
  final String id;
  final String ownerId;
  final String name;
  final String pricingInfo;
  final String location;
  final String contactNumber;
  final List<String> mediaUrls;
  final DateTime createdAt;
  final List<ShopService> services; // Changed to List<ShopService>

  RepairShop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.pricingInfo,
    required this.location,
    required this.contactNumber,
    required this.mediaUrls,
    required this.createdAt,
    this.services = const [], // Default to empty list of ShopService
  });

  factory RepairShop.fromMap(Map<String, dynamic> map) {
    return RepairShop(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String? ?? 'N/A',
      pricingInfo: map['pricing_info'] as String? ?? 'N/A',
      location: map['location'] as String? ?? 'N/A',
      contactNumber: map['contact_number'] as String? ?? 'N/A',
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
      createdAt: DateTime.parse(map['created_at'] as String),
      // Deserialize the JSONB array of services
      services: (map['services'] as List<dynamic>?)
              ?.map((serviceMap) =>
                  ShopService.fromMap(serviceMap as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'pricing_info': pricingInfo,
      'location': location,
      'contact_number': contactNumber,
      'media_urls': mediaUrls,
      'created_at': createdAt.toIso8601String(),
      'services': services.map((s) => s.toMap()).toList(),
    };
  }
}

// Define the nested ShopService model
class ShopService {
  final String id; // A local UUID for identifying services within the list
  final String name;
  final String description;
  final double? price;
  final List<String> mediaUrls; // New: media for individual services

  ShopService({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.mediaUrls = const [],
  });

  factory ShopService.fromMap(Map<String, dynamic> map) {
    return ShopService(
      id: map['id'] as String? ?? '', 
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble(),
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'media_urls': mediaUrls,
    };
  }

  // Helper for unique ID generation (optional, can be done when creating)
  ShopService.create({
    required this.name,
    required this.description,
    this.price,
    this.mediaUrls = const [],
  }) : id = Uuid().v4(); // Make sure you have 'package:uuid/uuid.dart' imported and Uuid() initialized

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopService &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          const ListEquality().equals(mediaUrls, other.mediaUrls); // Deep equality check

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      price.hashCode ^
      mediaUrls.hashCode;
}