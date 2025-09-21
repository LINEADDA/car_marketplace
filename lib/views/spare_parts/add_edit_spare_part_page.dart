import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  SparePartCondition _selectedCondition = SparePartCondition.usedGood;

  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();

    if (widget.isEditMode) {
      _loadPartForEditing();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadPartForEditing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final part = await _sparePartService.getPartById(widget.partId!);
      if (mounted && part != null) {
        setState(() {
          _titleController.text = part.title;
          _descriptionController.text = part.description;
          _priceController.text = part.price.toString();
          _selectedCondition = part.condition;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load part data: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to submit a part.');
      }

      final id =
          widget.isEditMode
              ? widget.partId!
              : Uuid().v4(); 

      final partData = SparePart(
        id: id,
        ownerId: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        condition: _selectedCondition,
        mediaUrls: [],
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Title cannot be empty'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SparePartCondition>(
                        initialValue: _selectedCondition,
                        decoration: const InputDecoration(
                          labelText: 'Condition',
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
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
                      const SizedBox(height: 32),
                      if (_isSubmitting)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: Text(
                            widget.isEditMode ? 'Save Changes' : 'Add Part',
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