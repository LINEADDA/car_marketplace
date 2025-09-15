import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/driver_location.dart';
import '../../models/ride.dart';
import '../../services/location_service.dart';
import '../../widgets/locator.dart'; 

class RiderTrackingPage extends StatefulWidget {
  final Ride ride;
  const RiderTrackingPage({super.key, required this.ride});

  @override
  State<RiderTrackingPage> createState() => _RiderTrackingPageState();
}

class _RiderTrackingPageState extends State<RiderTrackingPage> {
  late final LocationService _locationService;
  late final Stream<DriverLocation> _locationStream;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _myLocationEnabled = false; // 2. State variable for rider's location

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(Supabase.instance.client);
    _locationStream = _locationService.getDriverLocationStream(widget.ride.id);
    // 3. Check for permission to show rider's own location
    _enableMyLocation();
  }
  
  /// Checks for permission and updates the UI to show the rider's own location.
  void _enableMyLocation() async {
    final bool hasPermission = await handleLocationPermission();
    if(mounted) {
      setState(() {
        _myLocationEnabled = hasPermission;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Your Ride')),
      body: StreamBuilder<DriverLocation>(
        stream: _locationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Waiting for driver's location..."));
          }

          final location = snapshot.data!;
          final driverPosition = LatLng(location.latitude, location.longitude);

          _mapController?.animateCamera(CameraUpdate.newLatLng(driverPosition));

          _markers.clear();
          _markers.add(
            Marker(
              markerId: const MarkerId('driver_car'),
              position: driverPosition,
              rotation: location.heading ?? 0.0,
              infoWindow: const InfoWindow(title: 'Your Driver'),
            ),
          );

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: driverPosition, zoom: 16),
            markers: _markers,
            // 4. Use the state variable to control the "My Location" button
            myLocationEnabled: _myLocationEnabled,
            myLocationButtonEnabled: _myLocationEnabled,
          );
        },
      ),
    );
  }
}