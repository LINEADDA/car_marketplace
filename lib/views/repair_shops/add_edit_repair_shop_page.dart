// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditRepairShopPage extends StatefulWidget {
  final String? shopId;

  const AddEditRepairShopPage({super.key, this.shopId});

  bool get isEditMode => shopId != null;

  @override
  State<AddEditRepairShopPage> createState() => _AddEditRepairShopPageState();
}

class _AddEditRepairShopPageState extends State<AddEditRepairShopPage> {
  final _formKey = GlobalKey<FormState>();
  late final RepairShopService _repairShopService;
  late final MediaService _mediaService;

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _contactController;
  late final TextEditingController _pricingController;

  // State variables
  bool _isSubmitting = false;
  bool _isLoading = false;
  String? _errorMessage;
  RepairShop? _existingShop;

  // Media handling
  final List<XFile> _pickedImages = [];
  late List<String> _existingImageUrls;

  // Services management
  List<ShopService> _services = [];

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _mediaService = MediaService.forRepairShops(Supabase.instance.client);

    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _contactController = TextEditingController();
    _pricingController = TextEditingController();

    _existingImageUrls = [];

    if (widget.isEditMode) {
      _loadShopForEditing(widget.shopId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _pricingController.dispose();
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

  //// Below are unique repair shop related methods
  Future<void> _createUpdateShop() async {
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
        throw Exception('You must be logged in to submit a shop.');
      }

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final shopId = widget.isEditMode ? widget.shopId! : const Uuid().v4();

      List<String> removedMediaUrls = [];
      List<String> allImageUrls = [];

      if (widget.isEditMode && _existingShop != null) {
        // EDIT MODE: Track removed media URLs and combine existing + new images

        // Track which media URLs were removed
        final originalMediaUrls = _existingShop!.mediaUrls.toSet();
        final currentMediaUrls = _existingImageUrls.toSet();
        removedMediaUrls =
            originalMediaUrls.difference(currentMediaUrls).toList();

        // Upload new images and combine with existing ones
        final newImageUrls = await uploadNewImages(userId, shopId);
        allImageUrls = [..._existingImageUrls, ...newImageUrls];
      } else {
        // CREATE MODE: Just upload new images
        final newImageUrls = await uploadNewImages(userId, shopId);
        allImageUrls = newImageUrls;
      }

      final shopData = RepairShop(
        id: shopId,
        ownerId: currentUser.id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        contactNumber: _contactController.text.trim(),
        pricingInfo: _pricingController.text.trim(),
        mediaUrls: allImageUrls, // Use combined image URLs
        services: _services,
        createdAt:
            widget.isEditMode ? _existingShop!.createdAt : DateTime.now(),
      );

      if (widget.isEditMode) {
        // Update repair shop with removed media cleanup
        await _repairShopService.updateRepairShop(
          shopData,
          removedMediaUrls: removedMediaUrls,
        );
      } else {
        await _repairShopService.createRepairShop(shopData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Shop updated successfully'
                  : 'Shop added successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to submit shop: $e');
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

  Future<void> _loadShopForEditing(String shopId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final shop = await _repairShopService.getRepairShopById(shopId);
      if (mounted && shop != null) {
        // Get signed URLs for existing images
        final signedUrls = await _mediaService.getSignedMediaUrls(
          shop.mediaUrls,
        );

        setState(() {
          _existingShop = shop;
          _nameController.text = shop.name;
          _locationController.text = shop.location;
          _contactController.text = shop.contactNumber;
          _pricingController.text = shop.pricingInfo;
          _services = List.from(shop.services);
          _existingImageUrls = List.from(signedUrls);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Repair shop not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to load shop data: $e');
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

  // Service management methods
  Future<void> _showServiceDialog({ShopService? serviceToEdit}) async {
    final serviceFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: serviceToEdit?.name);
    final descCtrl = TextEditingController(text: serviceToEdit?.description);
    final priceCtrl = TextEditingController(
      text: serviceToEdit?.price?.toString() ?? '',
    );

    final result = await showDialog<ShopService>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(serviceToEdit == null ? 'Add Service' : 'Edit Service'),
          content: Form(
            key: serviceFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Service Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _validateRequired(v, 'Service Name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (serviceFormKey.currentState!.validate()) {
                  final newService = ShopService(
                    id: serviceToEdit?.id ?? const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text),
                    mediaUrls: serviceToEdit?.mediaUrls ?? [],
                  );
                  Navigator.of(context).pop(newService);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        if (serviceToEdit == null) {
          _services.add(result);
        } else {
          final index = _services.indexWhere((s) => s.id == result.id);
          if (index != -1) {
            _services[index] = result;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ScaffoldWithNav(
      title: widget.isEditMode ? 'Edit Repair Shop' : 'Add Repair Shop',
      currentRoute: '/repair-shops/add',
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
                      // Shop Details Section
                      _buildSectionCard(
                        context,
                        title: 'Shop Details',
                        children: [
                          _buildTextFormField(
                            controller: _nameController,
                            labelText: 'Shop Name *',
                            hintText: 'e.g., Kumar Auto Repairs',
                            validator:
                                (value) =>
                                    _validateRequired(value, 'Shop name'),
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _locationController,
                            labelText: 'Location *',
                            hintText: 'e.g., Mumbai, Maharashtra',
                            validator:
                                (value) => _validateRequired(value, 'Location'),
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
                              );
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
                            controller: _pricingController,
                            labelText: 'General Pricing Info (Optional)',
                            hintText: 'e.g., Starting from ₹500 per service',
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Services Section
                      _buildSectionCard(
                        context,
                        title: 'Services Offered',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Add services your shop offers',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: () => _showServiceDialog(),
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_services.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'No services added yet. Tap the + icon to add services.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _services.length,
                              itemBuilder: (context, index) {
                                final service = _services[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(service.name),
                                    subtitle:
                                        service.price != null
                                            ? Text('₹${service.price}')
                                            : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed:
                                              () => _showServiceDialog(
                                                serviceToEdit: service,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed:
                                              () => setState(() {
                                                _services.removeAt(index);
                                              }),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Images Section
                      _buildSectionCard(
                        context,
                        title: 'Images (Optional)',
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
                                  // Existing images from network
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
                                  // New picked images from local files
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
                          onPressed: _isSubmitting ? null : _createUpdateShop,
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
                                        ? 'Update Shop'
                                        : 'Add Shop',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),

                      // Error message display
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
                      _mediaService.previewMedia(
                        context,
                        MemoryImage(bytes),
                        file,
                        isVideo: false,
                      );
                    }
                    : () => _mediaService.previewMedia(
                      context,
                      imageProvider!,
                      null,
                      isVideo: false,
                    ),
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
                        image: imageProvider!,
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
