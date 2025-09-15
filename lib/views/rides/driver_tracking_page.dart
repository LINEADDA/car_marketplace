import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/driver_location.dart';
import '../../models/ride.dart';
import '../../services/location_service.dart';
import '../../widgets/locator.dart'; 

class DriverTrackingPage extends StatefulWidget {
  final Ride ride;
  const DriverTrackingPage({super.key, required this.ride});

  @override
  State<DriverTrackingPage> createState() => _DriverTrackingPageState();
}

class _DriverTrackingPageState extends State<DriverTrackingPage> {
  late final LocationService _locationService;
  StreamSubscription<Position>? _positionSubscription;
  final Set<Marker> _markers = {};
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(Supabase.instance.client);
    // 2. Call the new function that handles permission first
    _requestPermissionAndStartTracking();
  }

  /// Requests permission and starts location updates if granted.
  void _requestPermissionAndStartTracking() async {
    final bool hasPermission = await handleLocationPermission();

    if (!mounted) return;

    if (hasPermission) {
      setState(() {
        _isTracking = true;
      });
      _startLocationUpdates();
    } else {
      // Show an error message and potentially pop the page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to start tracking.'),
          backgroundColor: Colors.red,
        ),
      );
      // Optional: Automatically close the page if permission is denied
      Navigator.of(context).pop();
    }
  }

  /// Subscribes to the position stream and sends updates to Supabase.
  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      final driverLocation = DriverLocation(
        id: widget.ride.id, // Using ride.id for upsert onConflict
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        driverId: Supabase.instance.client.auth.currentUser!.id,
        rideId: widget.ride.id,
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
      );

      _locationService.upsertDriverLocation(driverLocation);

      if (mounted) {
        setState(() {
          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: LatLng(position.latitude, position.longitude),
              rotation: position.heading,
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking (Driver)')),
      // 3. Show the map if tracking, otherwise show a message
      body: _isTracking
          ? GoogleMap(
              initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 15),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            )
          : const Center(
              child: Text('Location permission denied.'),
            ),
    );
  }
}