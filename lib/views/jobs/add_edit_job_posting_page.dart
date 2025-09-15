import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/job_posting.dart';
import '../../services/job_service.dart';
import '../../widgets/custom_app_bar.dart';

class AddEditJobPostingPage extends StatefulWidget {
  final JobPosting? postingToEdit;
  const AddEditJobPostingPage({super.key, this.postingToEdit});

  @override
  State<AddEditJobPostingPage> createState() => _AddEditJobPostingPageState();
}

class _AddEditJobPostingPageState extends State<AddEditJobPostingPage> {
  final _formKey = GlobalKey<FormState>();
  late final JobService _jobService;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController(); // Controller for the new field
  String _selectedJobType = 'Full-time';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _jobService = JobService(Supabase.instance.client);
    if (widget.postingToEdit != null) {
      final post = widget.postingToEdit!;
      _titleController.text = post.jobTitle;
      _descriptionController.text = post.jobDescription ?? '';
      _locationController.text = post.location;
      _contactController.text = post.contactNumber; // Initialize controller
      _selectedJobType = post.jobType;
    }
  }

  Future<void> _savePosting() async {
    // 1. Ensure the form is valid before proceeding
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final posting = JobPosting(
          id: widget.postingToEdit?.id ?? const Uuid().v4(),
          ownerId: userId,
          jobTitle: _titleController.text.trim(),
          jobType: _selectedJobType,
          jobDescription: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          contactNumber: _contactController.text.trim(), // Pass the value
          isActive: widget.postingToEdit?.isActive ?? true,
          createdAt: widget.postingToEdit?.createdAt ?? DateTime.now(),
        );

        if (widget.postingToEdit == null) {
          await _jobService.createJobPosting(posting);
        } else {
          await _jobService.updateJobPosting(posting);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posting saved!')));
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
      appBar: CustomAppBar(title: widget.postingToEdit == null ? 'Post a Job' : 'Edit Job'),
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
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Job Title (e.g., Mechanic)'),
                      validator: (value) => value!.trim().isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedJobType,
                      decoration: const InputDecoration(labelText: 'Job Type'),
                      items: ['Full-time', 'Part-time', 'Contract'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) => setState(() => _selectedJobType = newValue!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location (e.g., City, State)'),
                      validator: (value) => value!.trim().isEmpty ? 'Please enter a location' : null,
                    ),
                    const SizedBox(height: 16),
                    // 2. Updated contact number field with validation
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.trim().isEmpty ? 'Contact number is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Job Description (Optional)'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _savePosting, child: const Text('Save Posting')),
                  ],
                ),
              ),
            ),
    );
  }
}