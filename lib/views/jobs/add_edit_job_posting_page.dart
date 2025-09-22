import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditJobPostingPage extends StatefulWidget {
  final String? postingId;

  const AddEditJobPostingPage({super.key, this.postingId});

  bool get isEditMode => postingId != null;

  @override
  State<AddEditJobPostingPage> createState() => _AddEditJobPostingPageState();
}

class _AddEditJobPostingPageState extends State<AddEditJobPostingPage> {
  final _formKey = GlobalKey<FormState>();
  late final JobService _jobService;
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobTypeController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    if (widget.isEditMode) {
      _loadJobPosting();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _jobTypeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadJobPosting() async {
    setState(() => _isLoading = true);
    try {
      final post = await _jobService.getJobPostingById(widget.postingId!);
      if (mounted && post != null) {
        setState(() {
          _titleController.text = post.jobTitle;
          _jobTypeController.text = post.jobType;
          _descriptionController.text = post.jobDescription ?? '';
          _locationController.text = post.location;
          _contactController.text = post.contactNumber;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePosting() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final ownerId = Supabase.instance.client.auth.currentUser!.id;
      final post = JobPosting(
        id: widget.postingId ?? const Uuid().v4(),
        ownerId: ownerId,
        jobTitle: _titleController.text.trim(),
        jobType: _jobTypeController.text.trim(),
        jobDescription: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        contactNumber: _contactController.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      if (widget.isEditMode) {
        await _jobService.updateJobPosting(post);
      } else {
        await _jobService.createJobPosting(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posting saved!')));
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
      title: widget.isEditMode ? 'Edit Job Posting' : 'Add Job Posting',
      currentRoute: '/jobs/postings/add',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Job Title'), validator: (v) => v!.isEmpty ? 'Title is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _jobTypeController, decoration: const InputDecoration(labelText: 'Job Type (e.g., Full-time, Contract)'), validator: (v) => v!.isEmpty ? 'Job Type is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location'), validator: (v) => v!.isEmpty ? 'Location is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact Phone Number'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Contact is required' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Job Description'), maxLines: 5),
                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: _savePosting, child: const Text('Save Posting')),
                ],
              ),
            ),
    );
  }
}