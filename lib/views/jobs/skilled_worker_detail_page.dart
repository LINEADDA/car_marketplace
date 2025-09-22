import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/skilled_worker.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class SkilledWorkerDetailPage extends StatefulWidget {
  final String workerId;
  const SkilledWorkerDetailPage({super.key, required this.workerId});

  @override
  State<SkilledWorkerDetailPage> createState() =>
      _SkilledWorkerDetailPageState();
}

class _SkilledWorkerDetailPageState extends State<SkilledWorkerDetailPage> {
  SkilledWorker? _worker;
  bool _isLoading = true;
  String? _errorMessage;
  late final SkilledWorkerService _skilledWorkerService;

  @override
  void initState() {
    super.initState();
    _skilledWorkerService = SkilledWorkerService(Supabase.instance.client);
    _fetchWorkerDetails();
  }

  Future<void> _fetchWorkerDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final worker = await _skilledWorkerService.getSkilledWorkerById(
        widget.workerId,
      );
      if (worker == null) {
        throw Exception('Worker not found.');
      }
      if (mounted) {
        setState(() {
          _worker = worker;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load worker details: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchMap(String location) async {
    final Uri mapUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': location,
    });
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
    }
  }

  Future<void> _launchPhoneDialer(
    String phoneNumber,
    BuildContext context,
  ) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to launch dialer: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: _isLoading ? 'Loading...' : _worker?.fullName ?? 'Worker Details',
      currentRoute: '/jobs/skilled-workers/${widget.workerId}',
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

    if (_worker == null) {
      return const Center(child: Text('Worker details not available.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _worker!.fullName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _worker!.primarySkill,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (_worker!.experienceHeadline != null &&
              _worker!.experienceHeadline!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _worker!.experienceHeadline!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // Location
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Location'),
            subtitle: Text(
              _worker!.location.isNotEmpty
                  ? _worker!.location
                  : 'Not specified',
              style: TextStyle(
                decoration:
                    _worker!.location.isNotEmpty
                        ? TextDecoration.underline
                        : TextDecoration.none,
                color:
                    _worker!.location.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
              ),
            ),
            onTap:
                _worker!.location.isNotEmpty
                    ? () => _launchMap(_worker!.location)
                    : null,
          ),
          // Contact
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Contact Number'),
            subtitle: Text(
              _worker!.contactNumber.isNotEmpty
                  ? _worker!.contactNumber
                  : 'Not available',
              style: TextStyle(
                decoration:
                    _worker!.contactNumber.isNotEmpty
                        ? TextDecoration.underline
                        : TextDecoration.none,
                color:
                    _worker!.contactNumber.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
              ),
            ),
            onTap:
                _worker!.contactNumber.isNotEmpty
                    ? () => _launchPhoneDialer(_worker!.contactNumber, context)
                    : null,
          ),
        ],
      ),
    );
  }
}

// Add a new service class to handle fetching skilled worker data
class SkilledWorkerService {
  final SupabaseClient _supabaseClient;
  SkilledWorkerService(this._supabaseClient);

  Future<SkilledWorker?> getSkilledWorkerById(String workerId) async {
    try {
      final response =
          await _supabaseClient
              .from('skilled_workers')
              .select()
              .eq('id', workerId)
              .single();
      return SkilledWorker.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching skilled worker: $e');
      return null;
    }
  }
}
