// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/spare_part.dart';
import '../../services/spare_part_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditSparePartPage extends StatefulWidget {
  final String? partId;

  const AddEditSparePartPage({super.key, this.partId});

  @override
  State<AddEditSparePartPage> createState() => AddEditSparePartPageState();
}

class AddEditSparePartPageState extends State<AddEditSparePartPage> {
  final formKey = GlobalKey<FormState>();
  late final SparePartService sparePartService;
  final uuid = const Uuid();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final contactController = TextEditingController();
  final locationController = TextEditingController();

  SparePartCondition selectedCondition = SparePartCondition.usedGood;

  SparePart? existingPart;

  final List<XFile> pickedImages = [];
  late List<String> existingImageUrls = [];

  bool isLoading = false;

  bool get isEditMode => widget.partId != null && existingPart != null;

  @override
  void initState() {
    super.initState();
    sparePartService = SparePartService(Supabase.instance.client);
    existingImageUrls = [];

    if (widget.partId != null) {
      loadPartForEdit(widget.partId!);
    }
  }

  Future<void> loadPartForEdit(String partId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final part = await sparePartService.getPartById(partId);
      if (part != null) {
        final signedUrls = await sparePartService.getSignedMediaUrls(
          part.mediaUrls,
        );
        if (!mounted) return;
        setState(() {
          existingPart = part;
          existingImageUrls = List.from(signedUrls);
          populateFields(part);
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spare part not found'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load spare part: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void populateFields(SparePart part) {
    titleController.text = part.title;
    descriptionController.text = part.description;
    priceController.text = part.price.toString();
    contactController.text = part.contact;
    locationController.text = part.location;
    selectedCondition = part.condition;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    contactController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // Removed validateImageFile and related image validation methods

  // Pick multiple images from gallery without validation
  Future<void> pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          pickedImages.addAll(images);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Take picture using camera without validation
  Future<void> takePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          pickedImages.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void removeImage(int index) {
    setState(() {
      pickedImages.removeAt(index);
    });
  }

  void removeExistingImage(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
    });
  }

  bool isVideoFile(XFile file) {
    final extension = file.path.toLowerCase().split('.').last;
    return extension == 'mp4' || extension == 'mov' || extension == 'avi';
  }

  // Show full screen preview of image or video
  void previewMedia(ImageProvider imageProvider, {bool isVideo = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            isVideo
                                ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image(
                                      image: imageProvider,
                                      fit: BoxFit.contain,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(128),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(179),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'VIDEO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : Image(
                                  image: imageProvider,
                                  fit: BoxFit.contain,
                                ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(153),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<List<String>> uploadNewImages(String userId, String partId) async {
    final newImageUrls = <String>[];
    for (final imageFile in pickedImages) {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final imageUrl = await sparePartService.uploadSparePartMedia(
        userId,
        partId,
        imageBytes,
      );
      newImageUrls.add(imageUrl);
    }
    return newImageUrls;
  }

  Future<void> createSparePart() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final partId = uuid.v4();

      final newImageUrls = await uploadNewImages(userId, partId);

      final partData = SparePart(
        id: partId,
        ownerId: userId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        condition: selectedCondition,
        mediaUrls: newImageUrls,
        contact: contactController.text.trim(),
        location: locationController.text.trim(),
        createdAt: DateTime.now(),
      );

      await sparePartService.createSparePart(partData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spare part listed successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating spare part: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateSparePart() async {
    if (!formKey.currentState!.validate()) return;
    if (existingPart == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final originalMediaUrls = existingPart!.mediaUrls.toSet();
      final currentMediaUrls = existingImageUrls.toSet();
      final removedMediaUrls =
          originalMediaUrls.difference(currentMediaUrls).toList();

      final newImageUrls = await uploadNewImages(userId, existingPart!.id);

      final allImageUrls = [...existingImageUrls, ...newImageUrls];

      final updatedPartData = SparePart(
        id: existingPart!.id,
        ownerId: existingPart!.ownerId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text.trim()),
        condition: selectedCondition,
        mediaUrls: allImageUrls,
        contact: contactController.text.trim(),
        location: locationController.text.trim(),
        createdAt: existingPart!.createdAt,
      );

      await sparePartService.updateSparePart(
        updatedPartData,
        removedMediaUrls: removedMediaUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spare part updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating spare part: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void handleSubmit() {
    if (isEditMode) {
      updateSparePart();
    } else {
      createSparePart();
    }
  }

  String? validateRequired(String? value, String fieldName) {
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
      title: isEditMode ? 'Edit Spare Part' : 'Add Spare Part',
      currentRoute: 'spare-parts/add',
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildSectionCard(
                        context,
                        title: 'Part Details',
                        children: [
                          buildTextFormField(
                            controller: titleController,
                            labelText: 'Part Name',
                            hintText: 'e.g., Brake Pads, Engine Oil',
                            validator: (v) => validateRequired(v, 'Part name'),
                          ),
                          const SizedBox(height: 16),
                          buildDropdownFormField<SparePartCondition>(
                            initialValue: selectedCondition,
                            labelText: 'Condition',
                            items:
                                SparePartCondition.values
                                    .map(
                                      (condition) => DropdownMenuItem(
                                        value: condition,
                                        child: Text(condition.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedCondition = v!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          buildTextFormField(
                            controller: priceController,
                            labelText: 'Price',
                            hintText: 'e.g., 2500',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Price is required';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildTextFormField(
                            controller: contactController,
                            labelText: 'Contact',
                            hintText: 'e.g., 9876543210',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Contact is required';
                              }
                              if (value.length < 10) {
                                return 'Contact must be at least 10 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          buildTextFormField(
                            controller: locationController,
                            labelText: 'Location',
                            hintText: 'e.g., Mumbai, Maharashtra',
                            validator: (v) => validateRequired(v, 'Location'),
                          ),
                          const SizedBox(height: 16),
                          buildTextFormField(
                            controller: descriptionController,
                            labelText: 'Description (Optional)',
                            hintText: 'Additional details...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      buildSectionCard(
                        context,
                        title: 'Images',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Choose from Gallery'),
                                  onPressed: pickImages,
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
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Take Photo'),
                                  onPressed: takePicture,
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
                          if (existingImageUrls.isNotEmpty ||
                              pickedImages.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ...existingImageUrls.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final url = entry.value;
                                    return buildImageThumbnail(
                                      imageProvider: NetworkImage(url),
                                      onRemove:
                                          () => removeExistingImage(index),
                                      file: null,
                                    );
                                  }),
                                  ...pickedImages.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final image = entry.value;
                                    return buildImageThumbnail(
                                      imageProvider: FileImage(
                                        File(image.path),
                                      ),
                                      onRemove: () => removeImage(index),
                                      file: image,
                                    );
                                  }),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleSubmit,
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
                              isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    isEditMode ? 'Update Part' : 'Save Part',
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

  Widget buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
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

  Widget buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
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

  Widget buildDropdownFormField<T>({
    required T initialValue,
    required String labelText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
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

  Widget buildImageThumbnail({
    required ImageProvider imageProvider,
    required VoidCallback onRemove,
    XFile? file,
  }) {
    final isVideo = file != null ? isVideoFile(file) : false;

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => previewMedia(imageProvider, isVideo: isVideo),
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
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError || snapshot.data == null) {
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
                          }
                          return Image.memory(
                            snapshot.data!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                      : Image(
                        image: imageProvider,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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
          if (isVideo)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          if (file == null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.visibility, color: Colors.white, size: 20),
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
                      color: Colors.black.withAlpha(80),
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
