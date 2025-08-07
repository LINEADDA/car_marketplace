import 'dart:convert';

enum FuelType { petrol, diesel, electric, hybrid, other }
enum Transmission { automatic, manual, other }

class Car {
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
    required this.createdAt,
  });

  Car copyWith({
    String? id,
    List<String>? mediaUrls,
    String? ownerId,
    String? make,
    String? model,
    int? year,
    bool? forSale,
    bool? isAvailable,
    String? location,
    bool? isPublic,
    String? description,
    int? mileage,
    FuelType? fuelType,
    Transmission? transmission,
    DateTime? createdAt,
  }) {
    return Car(
      id: id ?? this.id,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      ownerId: ownerId ?? this.ownerId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      forSale: forSale ?? this.forSale,
      isAvailable: isAvailable ?? this.isAvailable,
      location: location ?? this.location,
      isPublic: isPublic ?? this.isPublic,
      description: description ?? this.description,
      mileage: mileage ?? this.mileage,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      createdAt: createdAt ?? this.createdAt,
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
      'created_at': createdAt.toIso8601String(),
    };
  }

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
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Car.fromJson(String source) =>
      Car.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Car(id: $id, make: $make, model: $model, year: $year, ownerId: $ownerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Car &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.make == make &&
        other.model == model &&
        other.year == year;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerId.hashCode ^
        make.hashCode ^
        model.hashCode ^
        year.hashCode;
  }
}