import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSubmitting = false;
  String? _errorMessage;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobTypeController = TextEditingController();
  final _contactController = TextEditingController();
  final _salaryController = TextEditingController();

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
    _salaryController.dispose();
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
          _salaryController.text = post.salary;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePosting() async {
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
      final post = JobPosting(
        id: widget.postingId ?? const Uuid().v4(),
        ownerId: ownerId,
        jobTitle: _titleController.text.trim(),
        jobType: _jobTypeController.text.trim(),
        jobDescription: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        contactNumber: _contactController.text.trim(),
        salary: _salaryController.text.trim(),
        isActive: true,
        createdAt: DateTime.now(),
      );

      if (widget.isEditMode) {
        await _jobService.updateJobPosting(post);
      } else {
        await _jobService.createJobPosting(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode ? 'Job posting updated!' : 'Job posting added!',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save posting: $e';
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
      title: widget.isEditMode ? 'Edit Job Posting' : 'Add Job Posting',
      currentRoute: '/jobs/postings/add',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Job Title with required *
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Job Title *'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Job Title cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Job Type with required *
                      TextFormField(
                        controller: _jobTypeController,
                        decoration: _inputDecoration(
                          'Job Type (e.g., Full-time, Contract) *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Job Type cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // salary with numeric only and min length validation
                      TextFormField(
                        controller: _salaryController,
                        decoration: _inputDecoration('Salary per Month *'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLines: 1,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Salary cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Location with required *
                      TextFormField(
                        controller: _locationController,
                        decoration: _inputDecoration('Location *'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Contact with numeric only and min length validation
                      TextFormField(
                        controller: _contactController,
                        decoration: _inputDecoration('Contact Phone Number *'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLines: 1,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Contact cannot be empty';
                          }
                          if (value.trim().length < 10) {
                            return 'Contact must be at least 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Description optional, max 5 lines
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                          'Job Description (Optional)',
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 40),
                      if (_isSubmitting)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _savePosting,
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
                            widget.isEditMode
                                ? 'Save Changes'
                                : 'Add Job Posting',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
