import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  State<AddEditSkilledWorkerPage> createState() =>
      _AddEditSkilledWorkerPageState();
}

class _AddEditSkilledWorkerPageState extends State<AddEditSkilledWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  late final JobService _jobService;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

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
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(widget.isEditMode
                ? 'Worker profile updated!'
                : 'Worker profile added!'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: $e';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: widget.isEditMode ? 'Edit Application' : 'Add Application',
      currentRoute: '/jobs/skilled-workers/add',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Full Name * 
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Primary Skill *
                    TextFormField(
                      controller: _skillController,
                      decoration: _inputDecoration('Primary Skill (e.g., Mechanic) *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Skill is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Contact Phone Number with numeric and min length validation *
                    TextFormField(
                      controller: _contactController,
                      decoration: _inputDecoration('Contact Phone Number *'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLines: 1,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Contact must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Location *
                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration('Your Location (e.g., City, State) *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Location is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Experience Headline (Optional)
                    TextFormField(
                      controller: _experienceController,
                      decoration: _inputDecoration('Experience Headline (Optional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 40),
                    if (_isSubmitting)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          widget.isEditMode ? 'Save Changes' : 'Add Application',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}