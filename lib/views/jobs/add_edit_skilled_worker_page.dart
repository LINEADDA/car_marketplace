import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/skilled_worker.dart';
import '../../services/job_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditSkilledWorkerPage extends StatefulWidget {
  final String? workerId;

  const AddEditSkilledWorkerPage({super.key, this.workerId});

  bool get isEditMode => workerId != null;

  @override
  State<AddEditSkilledWorkerPage> createState() => _AddEditSkilledWorkerPageState();
}

class _AddEditSkilledWorkerPageState extends State<AddEditSkilledWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  late final JobService _jobService;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _skillController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    if (widget.isEditMode) {
      _loadWorkerProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skillController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerProfile() async {
    setState(() => _isLoading = true);
    try {
      final worker = await _jobService.getSkilledWorkerById(widget.workerId!);
      if (mounted && worker != null) {
        setState(() {
          _nameController.text = worker.fullName;
          _skillController.text = worker.primarySkill;
          _experienceController.text = worker.experienceHeadline ?? '';
          _locationController.text = worker.location;
          _contactController.text = worker.contactNumber;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final ownerId = Supabase.instance.client.auth.currentUser!.id;
      final worker = SkilledWorker(
        id: widget.workerId ?? const Uuid().v4(),
        ownerId: ownerId,
        fullName: _nameController.text.trim(),
        primarySkill: _skillController.text.trim(),
        experienceHeadline: _experienceController.text.trim(),
        location: _locationController.text.trim(),
        contactNumber: _contactController.text.trim(),
        isAvailable: true,
        createdAt: DateTime.now(),
      );

      if (widget.isEditMode) {
        await _jobService.updateSkilledWorker(worker);
      } else {
        await _jobService.createSkilledWorker(worker);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Worker profile saved!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: widget.isEditMode ? 'Edit Worker Profile' : 'Create Worker Profile',
      currentRoute: '/jobs/skilled-workers/add',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name'), validator: (v) => v!.isEmpty ? 'Name is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _skillController, decoration: const InputDecoration(labelText: 'Primary Skill (e.g., Mechanic)'), validator: (v) => v!.isEmpty ? 'Skill is required' : null),
                   const SizedBox(height: 16),
                  TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Contact is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Your Location (e.g., City, State)'), validator: (v) => v!.isEmpty ? 'Location is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _experienceController, decoration: const InputDecoration(labelText: 'Experience Headline (Optional)'), maxLines: 2),
                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: _saveProfile, child: const Text('Save Profile')),
                ],
              ),
            ),
    );
  }
}