import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/skilled_worker.dart';
import '../../services/job_service.dart';
import '../../widgets/custom_app_bar.dart';

class AddEditSkilledWorkerPage extends StatefulWidget {
  final SkilledWorker? workerToEdit;
  const AddEditSkilledWorkerPage({super.key, this.workerToEdit});

  @override
  State<AddEditSkilledWorkerPage> createState() => _AddEditSkilledWorkerPageState();
}

class _AddEditSkilledWorkerPageState extends State<AddEditSkilledWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  late final JobService _jobService;
  final _nameController = TextEditingController();
  final _skillController = TextEditingController();
  final _headlineController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    if (widget.workerToEdit != null) {
      final worker = widget.workerToEdit!;
      _nameController.text = worker.fullName;
      _skillController.text = worker.primarySkill;
      _headlineController.text = worker.experienceHeadline ?? '';
      _locationController.text = worker.location;
      _contactController.text = worker.contactNumber;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final worker = SkilledWorker(
          id: widget.workerToEdit?.id ?? const Uuid().v4(),
          ownerId: userId,
          fullName: _nameController.text,
          primarySkill: _skillController.text,
          experienceHeadline: _headlineController.text,
          location: _locationController.text,
          contactNumber: _contactController.text,
          isAvailable: true,
          createdAt: widget.workerToEdit?.createdAt ?? DateTime.now(),
        );

        if (widget.workerToEdit == null) {
          await _jobService.createSkilledWorker(worker);
        } else {
          await _jobService.updateSkilledWorker(worker);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.workerToEdit == null ? 'Create Worker Profile' : 'Edit Profile'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skillController,
                      decoration: const InputDecoration(labelText: 'Primary Skill (e.g., Mechanic)'),
                      validator: (value) => value!.isEmpty ? 'Please enter your skill' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Your Location (e.g., City, State)'),
                      validator: (value) => value!.isEmpty ? 'Please enter your location' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _headlineController,
                      decoration: const InputDecoration(labelText: 'Experience Headline (Optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _saveProfile, child: const Text('Save Profile')),
                  ],
                ),
              ),
            ),
    );
  }
}