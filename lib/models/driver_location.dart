import 'dart:convert';

class DriverLocation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String driverId;
  final String rideId;
  final double latitude;
  final double longitude;
  final double? heading;

  DriverLocation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.driverId,
    required this.rideId,
    required this.latitude,
    required this.longitude,
    this.heading,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'driver_id': driverId,
      'ride_id': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
    };
  }

  factory DriverLocation.fromMap(Map<String, dynamic> map) {
    return DriverLocation(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      driverId: map['driver_id'] as String,
      rideId: map['ride_id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      heading: (map['heading'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DriverLocation.fromJson(String source) => DriverLocation.fromMap(json.decode(source));
}