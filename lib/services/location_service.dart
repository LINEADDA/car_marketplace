import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_location.dart'; 

class LocationService {
  final SupabaseClient _client;

  LocationService(this._client);

  /// Inserts or updates a driver's location for a specific ride.
  /// 'upsert' is highly efficient for frequent updates like GPS data.
  Future<void> upsertDriverLocation(DriverLocation location) async {
    // This will insert a new row or update an existing one if a row
    // with the same 'ride_id' already exists. This assumes one location
    // entry per ride that is continuously updated.
    await _client.from('driver_locations').upsert(location.toMap(), onConflict: 'ride_id');
  }

  /// Provides a real-time stream of a driver's location for a given ride.
  /// This is the core function for the rider's live tracking map.
  Stream<DriverLocation> getDriverLocationStream(String rideId) {
    return _client
        .from('driver_locations')
        .stream(primaryKey: ['id'])
        .eq('ride_id', rideId)
        .map((maps) {
          if (maps.isEmpty) {
            // This can happen if the driver hasn't sent their first location yet.
            // The UI should handle this state, perhaps by showing a "Waiting for driver..." message.
            throw Exception('No location data available yet for this ride.');
          }
          // The stream provides a list, but we only care about the single, most recent entry.
          return DriverLocation.fromMap(maps.first);
        });
  }
}