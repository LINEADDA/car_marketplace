import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ride.dart'; 

class RideService {
  final SupabaseClient _client;

  RideService(this._client);

  /// Creates a new ride request in the database and returns the created ride.
  Future<Ride> createRide(Ride ride) async {
    final response = await _client.from('rides').insert(ride.toMap()).select().single();
    return Ride.fromMap(response);
  }

  /// Fetches a single ride by its ID.
  Future<Ride?> getRide(String rideId) async {
    final response = await _client.from('rides').select().eq('id', rideId).maybeSingle();
    if (response == null) {
      return null;
    }
    return Ride.fromMap(response);
  }

  /// Updates the status of a ride (e.g., 'accepted', 'in_progress', 'completed').
  Future<void> updateRideStatus(String rideId, String status) async {
    await _client.from('rides').update({'status': status}).eq('id', rideId);
  }
  
  /// Accepts a ride by setting its status to 'accepted' and assigning the driver.
  Future<void> acceptRide(String rideId, String driverId) async {
    await _client
        .from('rides')
        .update({'status': 'accepted', 'driver_id': driverId})
        .eq('id', rideId);
  }

  /// Provides a stream of real-time updates for a specific ride.
  /// This is useful for the rider and driver to see status changes live.
  Stream<Ride> getRideStream(String rideId) {
    return _client
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', rideId)
        .map((maps) => Ride.fromMap(maps.first));
  }
}