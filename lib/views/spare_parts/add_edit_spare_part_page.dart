import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_app_bar.dart';

class AddEditSparePartPage extends StatefulWidget {
  final SparePart? partToEdit;
  const AddEditSparePartPage({super.key, this.partToEdit});

  @override
  State<AddEditSparePartPage> createState() => _AddEditSparePartPageState();
}

class _AddEditSparePartPageState extends State<AddEditSparePartPage> {
  final _formKey = GlobalKey<FormState>();
  late final SparePartService _sparePartService;
  final _uuid = const Uuid();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  SparePartCondition _selectedCondition = SparePartCondition.brandNew;
  final List<XFile> _pickedImages = [];
  late List<String> _existingImageUrls;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _existingImageUrls = List<String>.from(widget.partToEdit?.mediaUrls ?? []);

    if (widget.partToEdit != null) {
      final part = widget.partToEdit!;
      _titleController.text = part.title;
      _descriptionController.text = part.description;
      _priceController.text = part.price.toString();
      _selectedCondition = part.condition;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) setState(() => _pickedImages.addAll(images));
  }

  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final partId = widget.partToEdit?.id ?? _uuid.v4();
      final updatedImageUrls = List<String>.from(_existingImageUrls);

      for (final imageFile in _pickedImages) {
        final imageUrl = await _sparePartService.uploadSparePartMediaFile(userId, partId, File(imageFile.path));
        updatedImageUrls.add(imageUrl);
      }

      final partData = SparePart(
        id: partId,
        ownerId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        condition: _selectedCondition,
        createdAt: widget.partToEdit?.createdAt ?? DateTime.now(),
        mediaUrls: updatedImageUrls,
      );

      widget.partToEdit == null
          ? await _sparePartService.createSparePart(partData)
          : await _sparePartService.updateSparePart(partData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Part saved successfully!')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving part: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(title: widget.partToEdit == null ? 'Add Spare Part' : 'Edit Part'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Part Title'), validator: (v) => Validators.validateNotEmpty(v, 'Title')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price (\$)', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number, validator: (v) => Validators.validateNotEmpty(v, 'Price')),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SparePartCondition>(
                        initialValue: _selectedCondition,
                        decoration: const InputDecoration(labelText: 'Condition'),
                        items: SparePartCondition.values.map((condition) {
                          return DropdownMenuItem(value: condition, child: Text(condition.name));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _selectedCondition = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 4, validator: (v) => Validators.validateNotEmpty(v, 'Description')),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(onPressed: _pickImages, icon: const Icon(Icons.add_a_photo), label: const Text('Add Photos')),
                      // Image display logic...
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _savePart, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)), child: const Text('Save Part')),
                    ],
                  ),
                ),
              ),
      );
  }
}