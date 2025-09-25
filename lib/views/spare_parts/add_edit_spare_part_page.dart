// ignore_for_file: avoid_print

// import 'dart:io';
// import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditSparePartPage extends StatefulWidget {
  final String? partId;

  const AddEditSparePartPage({super.key, this.partId});

  bool get isEditMode => partId != null;

  @override
  State<AddEditSparePartPage> createState() => _AddEditSparePartPageState();
}

class _AddEditSparePartPageState extends State<AddEditSparePartPage> {
  final _formKey = GlobalKey<FormState>();
  late final SparePartService _sparePartService;
  //final _uuid = const Uuid();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _contactController;
  late final TextEditingController _locationController;

  SparePartCondition _selectedCondition = SparePartCondition.usedGood;

  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _errorMessage;

  // final List<XFile> _pickedImages = [];
  // late List<String> _existingImageUrls;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _contactController = TextEditingController();
    _locationController = TextEditingController();
    //_existingImageUrls = [];

    if (widget.isEditMode) {
      _loadPartForEditing(widget.partId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadPartForEditing(String partId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final part = await _sparePartService.getPartById(partId);
      if (mounted && part != null) {

        //final signedUrls = await _sparePartService.getSignedMediaUrls(part.mediaUrls);

        setState(() {
          _titleController.text = part.title;
          _descriptionController.text = part.description;
          _priceController.text = part.price.toString();
          _contactController.text = part.contact.toString();
          _locationController.text = part.location;
          _selectedCondition = part.condition;
          //_existingImageUrls = List.from(signedUrls);
        });
      }else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spare part not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load part data: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createUpdatePart() async {
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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to submit a part.');
      }

      final id = widget.isEditMode ? widget.partId! : const Uuid().v4();

      final partData = SparePart(
        id: id,
        ownerId: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        condition: _selectedCondition,
        mediaUrls: [],
        contact: _contactController.text.trim(),
        location: _locationController.text.trim(),
        createdAt: DateTime.now(),
      );

      if (widget.isEditMode) {
        await _sparePartService.updateSparePart(partData);
      } else {
        await _sparePartService.createSparePart(partData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Part updated successfully'
                  : 'Part added successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to submit part: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNav(
      title: widget.isEditMode ? 'Edit Spare Part' : 'Add Spare Part',
      currentRoute: '/spare-parts/add',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && !_isSubmitting
              ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title Field with validation
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Part name *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Part name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<SparePartCondition>(
                        initialValue: _selectedCondition,
                        decoration: InputDecoration(
                          labelText: 'Condition *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items:
                            SparePartCondition.values
                                .map(
                                  (condition) => DropdownMenuItem(
                                    value: condition,
                                    child: Text(condition.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCondition = value);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      // Price Field with validation
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Price cannot be empty';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Price must be positive';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Contact Field with validation
                      TextFormField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          labelText: 'Contact *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
                        maxLines: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Contact cannot be empty';
                          }
                          if (value.length < 10) {
                            return 'Contact must be at least 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Location Field with validation
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Location cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // Description Field without a validator
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 40),
                      if (_isSubmitting)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _createUpdatePart,
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
                            widget.isEditMode ? 'Save Changes' : 'Add Part',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (_errorMessage != null && _isSubmitting)
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