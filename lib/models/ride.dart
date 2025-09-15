import 'dart:convert';

class Ride {
  final String id;
  final DateTime createdAt;
  final String riderId;
  final String? driverId;
  final String status;
  final String? origin;
  final String? destination;
  final double? price;

  Ride({
    required this.id,
    required this.createdAt,
    required this.riderId,
    this.driverId,
    required this.status,
    this.origin,
    this.destination,
    this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'rider_id': riderId,
      'driver_id': driverId,
      'status': status,
      'origin': origin,
      'destination': destination,
      'price': price,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      riderId: map['rider_id'] as String,
      driverId: map['driver_id'] as String?,
      status: map['status'] as String,
      origin: map['origin'] as String?,
      destination: map['destination'] as String?,
      // Handle numeric types safely, as they can come in as int or double
      price: (map['price'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Ride.fromJson(String source) => Ride.fromMap(json.decode(source));
}