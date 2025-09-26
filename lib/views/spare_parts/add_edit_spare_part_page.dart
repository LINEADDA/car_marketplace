// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../services/media_service.dart';
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
  late final MediaService _mediaService;

  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _contactController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  SparePartCondition _selectedCondition = SparePartCondition.usedGood;

  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _errorMessage;
  SparePart? _existingPart;

  final List<XFile> _pickedImages = [];
  late List<String> _existingImageUrls;

  @override
  void initState() {
    super.initState();
    _sparePartService = SparePartService(Supabase.instance.client);
    _mediaService = MediaService.forSpareParts(Supabase.instance.client);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _contactController = TextEditingController();
    _locationController = TextEditingController();
    _existingImageUrls = [];

    if (widget.isEditMode) {
      _loadPartForEditing(widget.partId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  //// Helper methods for media_service file
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  void _hideLoadingDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  MediaServiceCallbacks get _callbacks => MediaServiceCallbacks(
    onFilesAdded: (files) {
      setState(() {
        _pickedImages.addAll(files);
      });
    },
    onFileRemoved: (index) {
      setState(() {
        _pickedImages.removeAt(index);
      });
    },
    onExistingFileRemoved: (index) {
      setState(() {
        _existingImageUrls.removeAt(index);
      });
    },
    onShowSnackBar: _showSnackBar,
    onShowLoading: () => _showLoadingDialog('Processing images...'),
    onHideLoading: _hideLoadingDialog,
  );

  //// Below are unique spare parts related methods
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

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final partId = widget.isEditMode ? widget.partId! : const Uuid().v4();

      List<String> removedMediaUrls = [];
      List<String> allImageUrls = [];

      if (widget.isEditMode && _existingPart != null) {
        final originalMediaUrls = _existingPart!.mediaUrls.toSet();
        final currentMediaUrls = _existingImageUrls.toSet();
        removedMediaUrls = originalMediaUrls.difference(currentMediaUrls).toList();

        final newImageUrls = await uploadNewImages(userId, partId);
        allImageUrls = [..._existingImageUrls, ...newImageUrls];
      } else {
        final newImageUrls = await uploadNewImages(userId, partId);
        allImageUrls = newImageUrls;
      }

      final partData = SparePart(
        id: partId,
        ownerId: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        condition: _selectedCondition,
        mediaUrls: allImageUrls, 
        contact: _contactController.text.trim(),
        location: _locationController.text.trim(),
        createdAt:
            widget.isEditMode ? _existingPart!.createdAt : DateTime.now(),
      );

      if (widget.isEditMode) {
        await _sparePartService.updateSparePart(
          partData,
          removedMediaUrls: removedMediaUrls,
        );
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

  Future<List<String>> uploadNewImages(String userId, String itemId) async {
    final newImageUrls = <String>[];

    for (final imageFile in _pickedImages) {
      try {
        final imageBytes = await imageFile.readAsBytes();
        final imageUrl = await _mediaService.uploadMedia(
          userId,
          itemId,
          imageBytes,
        );
        newImageUrls.add(imageUrl);
      } catch (e) {
        _showSnackBar(
          'Failed to upload ${imageFile.name}: $e',
          backgroundColor: Colors.red,
        );
      }
    }

    return newImageUrls;
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

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Part Details Section
                      _buildSectionCard(
                        context,
                        title: 'Part Details',
                        children: [
                          _buildTextFormField(
                            controller: _titleController,
                            labelText: 'Part Name *',
                            hintText: 'e.g., Brake Pad, Headlight',
                            validator:
                                (value) => _validateRequired(
                                  value,
                                  'Part name',
                                ), // USING YOUR METHOD
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownFormField<SparePartCondition>(
                            initialValue: _selectedCondition,
                            labelText: 'Condition *',
                            items:
                                SparePartCondition.values
                                    .map(
                                      (condition) => DropdownMenuItem(
                                        value: condition,
                                        child: Text(
                                          condition.name.toUpperCase(),
                                        ),
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
                          _buildTextFormField(
                            controller: _priceController,
                            labelText: 'Price (₹) *',
                            hintText: 'e.g., 2500',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*'),
                              ),
                            ],
                            validator: (value) {
                              final requiredValidation = _validateRequired(
                                value,
                                'Price',
                              ); // USING YOUR METHOD
                              if (requiredValidation != null) {
                                return requiredValidation;
                              }

                              if (double.tryParse(value!) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value) <= 0) {
                                return 'Price must be positive';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _contactController,
                            labelText: 'Contact Number *',
                            hintText: 'e.g., 9876543210',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              final requiredValidation = _validateRequired(
                                value,
                                'Contact',
                              ); // USING YOUR METHOD
                              if (requiredValidation != null) {
                                return requiredValidation;
                              }

                              if (value!.length < 10) {
                                return 'Contact must be at least 10 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _locationController,
                            labelText: 'Location *',
                            hintText: 'e.g., Mumbai, Maharashtra',
                            validator:
                                (value) => _validateRequired(
                                  value,
                                  'Location',
                                ), // USING YOUR METHOD
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _descriptionController,
                            labelText: 'Description (Optional)',
                            hintText: 'Additional details about the part...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24,),
                      _buildSectionCard(
                        context,
                        title: "Images (Optional)",
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      () => _mediaService.pickImages(
                                        context,
                                        _callbacks,
                                      ),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Choose from Gallery'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      () => _mediaService.takePicture(
                                        context,
                                        _callbacks,
                                      ),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Take Photo'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_existingImageUrls.isNotEmpty ||
                              _pickedImages.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ..._existingImageUrls.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final url = entry.value;
                                    return _buildImageThumbnail(
                                      imageProvider: NetworkImage(url),
                                      onRemove:
                                          () =>
                                              _mediaService.removeExistingFile(
                                                index,
                                                _callbacks,
                                              ),
                                      file: null,
                                    );
                                  }),
                                  ..._pickedImages.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final image = entry.value;
                                    return _buildImageThumbnail(
                                      imageProvider: null,
                                      onRemove:
                                          () => _mediaService.removeFile(
                                            index,
                                            _callbacks,
                                          ),
                                      file: image,
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _createUpdatePart,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            elevation: 8,
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    widget.isEditMode
                                        ? 'Update Part'
                                        : 'Add Part',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Below all methods can be made re-useable
  // Helpful in created separate parts
  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  // For building consistent text input fields 
  Widget _buildTextFormField({required TextEditingController controller, required String labelText, String? hintText, TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.withAlpha(25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }
  
  // Dropdown List
  Widget _buildDropdownFormField<T>({required T initialValue, required String labelText, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey.withAlpha(25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // As name suggests, Builds thumbnails for selected images
  Widget _buildImageThumbnail({ImageProvider? imageProvider, required VoidCallback onRemove, XFile? file}) {
  
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100,
      child: Stack(
        children: [
          GestureDetector(
            onTap:
                file != null
                    ? () async {
                      final bytes = await file.readAsBytes();
                      if (!mounted) return;
                       _mediaService.previewMedia(context, MemoryImage(bytes), file, isVideo: false);
                    }
                    : () => _mediaService.previewMedia(context, imageProvider!, null, isVideo: false),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  file != null
                      ? FutureBuilder<Uint8List>(
                        future: file.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          } else if (snapshot.hasError ||
                              snapshot.data == null) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: Colors.red,
                                    size: 30,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Invalid',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Image.memory(
                            snapshot.data!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('File image loading error: $error');
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Error',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      )
                      : Image(
                        image: imageProvider!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Network image loading error: $error');
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

}