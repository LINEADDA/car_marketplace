import 'dart:convert';

// Enums to match your custom types in Supabase
enum FuelType { petrol, diesel, electric, hybrid, cng, other }
enum Transmission { automatic, manual, other }

class Car {
  // Properties ordered exactly as in the database schema
  final String id;
  final List<String> mediaUrls;
  final String ownerId;
  final String make;
  final String model;
  final int year;
  final bool forSale;
  final bool isAvailable;
  final String location;
  final bool isPublic;
  final String description;
  final int mileage;
  final FuelType fuelType;
  final Transmission transmission;
  final double? salePrice;
  final double? bookingRatePerDay;
  final DateTime createdAt;

  Car({
    required this.id,
    required this.mediaUrls,
    required this.ownerId,
    required this.make,
    required this.model,
    required this.year,
    required this.forSale,
    required this.isAvailable,
    required this.location,
    required this.isPublic,
    required this.description,
    required this.mileage,
    required this.fuelType,
    required this.transmission,
    this.salePrice,
    this.bookingRatePerDay,
    required this.createdAt,
  });

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      mediaUrls: List<String>.from(map['media_urls'] as List),
      ownerId: map['owner_id'] as String,
      make: map['make'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      forSale: map['for_sale'] as bool,
      isAvailable: map['is_available'] as bool,
      location: map['location'] as String,
      isPublic: map['is_public'] as bool,
      description: map['description'] as String,
      mileage: map['mileage'] as int,
      fuelType: FuelType.values.byName(map['fuel_type'] as String),
      transmission: Transmission.values.byName(map['transmission'] as String),
      salePrice: (map['sale_price'] as num?)?.toDouble(),
      bookingRatePerDay: (map['booking_rate_per_day'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'media_urls': mediaUrls,
      'owner_id': ownerId,
      'make': make,
      'model': model,
      'year': year,
      'for_sale': forSale,
      'is_available': isAvailable,
      'location': location,
      'is_public': isPublic,
      'description': description,
      'mileage': mileage,
      'fuel_type': fuelType.name,
      'transmission': transmission.name,
      'sale_price': salePrice,
      'booking_rate_per_day': bookingRatePerDay,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String toJson() => json.encode(toMap());

  factory Car.fromJson(String source) =>
      Car.fromMap(json.decode(source) as Map<String, dynamic>);
}
