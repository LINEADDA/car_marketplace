import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../services/config_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';
import '../../widgets/media_carousel.dart';
import '../../widgets/full_screen_media_viewer.dart';

class CarDetailPage extends StatefulWidget {
  final String carId;
  const CarDetailPage({super.key, required this.carId});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  late final CarService _carService;
  late final ConfigService _configService;

  Car? _car;
  List<String> _signedMediaUrls = [];
  String? _adminContactNumber;
  String? _ownerContactNumber;
  bool _isLoading = true;
  String? _errorMessage;

  String get _carTitle =>
      _car != null
          ? '${_car!.year} ${_car!.make} ${_car!.model}'
          : 'Car Details';
  bool get _isOwner =>
      _car?.ownerId == Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _configService = ConfigService(Supabase.instance.client);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final carFuture = _carService.getCarById(widget.carId);
      final contactFuture = _configService.getAdminContactNumber();
      final results = await Future.wait([carFuture, contactFuture]);

      final car = results[0] as Car?;
      final adminContact = results[1] as String?;

      if (car == null) throw Exception('Car not found.');

      // Generate signed URLs for media
      final signedUrls = await _carService.getSignedMediaUrls(car.mediaUrls);

      String? displayedContact;
      if (car.forSale) {
        displayedContact = adminContact;
      } else {
        displayedContact = car.contact;
      }

      if (mounted) {
        setState(() {
          _car = car;
          _signedMediaUrls = signedUrls;
          _adminContactNumber = adminContact;
          _ownerContactNumber = displayedContact;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load details: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  // Full-screen media viewer
  void _showFullScreenMedia(List<String> mediaUrls) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                FullScreenMediaViewer(mediaUrls: mediaUrls, initialIndex: 0),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: true,
        opaque: false,
      ),
    );
  }

  Future<void> _handleDeleteCar(Car car) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Car'),
            content: Text(
              'Are you sure you want to permanently delete this ${car.make} ${car.model}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _carService.deleteCar(car.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Car deleted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete car: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _launchDialer(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer.')),
        );
      }
    }
  }

  Future<void> _launchMap(String location) async {
    final Uri launchUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: _isLoading ? 'Loading...' : _carTitle,
      currentRoute: '/cars/${widget.carId}',
      actions: [
        if (_isOwner && _car != null) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Car',
            onPressed: () => context.push('/cars/edit/${_car!.id}'),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete Car',
            onPressed: () => _handleDeleteCar(_car!),
          ),
        ],
      ],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_car == null) {
      return const Center(child: Text('Car details not available.'));
    }

    final car = _car!;
    final mileageFormatter = NumberFormat.decimalPattern('en_IN');
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
    );

    final String? contactNumber =
        car.forSale ? _adminContactNumber : _ownerContactNumber;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use signed URLs for media carousel
          MediaCarousel(
            mediaUrls: _signedMediaUrls,
            onFullScreen: () => _showFullScreenMedia(_signedMediaUrls),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _carTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPriceDisplay(car, currencyFormatter),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    _buildSpecChip(
                      Icons.speed_outlined,
                      '${mileageFormatter.format(car.mileage)} Km/L',
                    ),
                    _buildSpecChip(
                      Icons.local_gas_station_outlined,
                      car.fuelType.name.toUpperCase(),
                    ),
                    _buildSpecChip(
                      Icons.settings_outlined,
                      car.transmission.name.toUpperCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Description'),
                  subtitle: Text(
                    car.description.isNotEmpty
                        ? car.description
                        : 'No description provided.',
                  ),
                ),
                ListTile(
                  onTap: () => _launchMap(car.location),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Location'),
                  subtitle: Text(
                    car.location,
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                ListTile(
                  onTap: () {
                    if (contactNumber != null) {
                      _launchDialer(contactNumber);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Contact'),
                  subtitle: Text(
                    contactNumber ?? 'Not available',
                    style: TextStyle(
                      decoration:
                          contactNumber != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                      color:
                          contactNumber != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(Car car, NumberFormat currencyFormatter) {
    if (car.forSale && car.salePrice != null) {
      return Text(
        currencyFormatter.format(car.salePrice),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (!car.forSale && car.bookingRatePerDay != null) {
      return RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: currencyFormatter.format(car.bookingRatePerDay)),
            TextSpan(
              text: ' / day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        'Price not available',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Colors.grey),
      );
    }
  }

  Widget _buildSpecChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}