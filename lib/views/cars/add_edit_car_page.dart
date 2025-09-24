// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditCarPage extends StatefulWidget {
  final String? carId;
  final String? initialListingType;

  const AddEditCarPage({super.key, this.carId, this.initialListingType});

  @override
  State<AddEditCarPage> createState() => _AddEditCarPageState();
}

class _AddEditCarPageState extends State<AddEditCarPage> {
  final _formKey = GlobalKey<FormState>();
  late final CarService _carService;
  final _uuid = const Uuid();

  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _bookingRateController = TextEditingController();

  FuelType _selectedFuelType = FuelType.petrol;
  Transmission _selectedTransmission = Transmission.manual;
  bool _isForSale = false;
  String? _userRole;
  Car? _existingCar;

  final List<XFile> _pickedImages = [];
  late List<String> _existingImageUrls;
  bool _isLoading = false;

  // Determine if we're editing or creating based on carId
  bool get _isEditMode => widget.carId != null && _existingCar != null;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _fetchUserRole();

    if (widget.initialListingType != null) {
      _isForSale = widget.initialListingType == 'sale';
    }

    _existingImageUrls = [];

    if (widget.carId != null) {
      _loadCarForEdit(widget.carId!);
    }
  }

  Future<void> _loadCarForEdit(String carId) async {
    setState(() => _isLoading = true);

    try {
      final car = await _carService.getCarById(carId);
      if (car != null && mounted) {
        // Generate signed URLs for existing media
        final signedUrls = await _carService.getSignedMediaUrls(car.mediaUrls);

        setState(() {
          _existingCar = car;
          _existingImageUrls = List.from(signedUrls); // Use signed URLs
          _populateFields(car);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Car not found'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load car: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _userRole = null;
          _isForSale = true;
        });
      }
      return;
    }
    try {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', userId)
              .single();

      if (mounted) {
        final role = (response['role'] as String?)?.toLowerCase();
        setState(() {
          _userRole = role;
          if (role == 'driver' && widget.carId == null) {
            _isForSale = false; // Default to booking for new cars by drivers
          } else if (widget.carId == null) {
            _isForSale = true; // Default to sale for new cars by non-drivers
          }
          // For existing cars, _isForSale will be set when loading car data
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isForSale = true);
    }
  }

  void _populateFields(Car car) {
    _makeController.text = car.make;
    _modelController.text = car.model;
    _yearController.text = car.year.toString();
    _mileageController.text = car.mileage.toString();
    _locationController.text = car.location;
    _contactController.text = car.contact;
    _descriptionController.text = car.description;
    _salePriceController.text = car.salePrice?.toString() ?? '';
    _bookingRateController.text = car.bookingRatePerDay?.toString() ?? '';
    _selectedFuelType = car.fuelType;
    _selectedTransmission = car.transmission;
    _isForSale = car.forSale;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    _salePriceController.dispose();
    _bookingRateController.dispose();
    super.dispose();
  }

  // Image validation method
  Future<bool> _validateImageFile(XFile file) async {
    try {
      final fileExists = await File(file.path).exists();
      if (!fileExists) return false;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return false;

      // Check if it's a valid image by trying to decode it
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image.width > 0 && frame.image.height > 0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        // Show loading dialog while validating images
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Validating images...'),
                    ],
                  ),
                ),
          );
        }

        // Validate images before adding
        final validImages = <XFile>[];
        final invalidImageNames = <String>[];

        for (final image in images) {
          final isValid = await _validateImageFile(image);
          if (isValid) {
            validImages.add(image);
          } else {
            invalidImageNames.add(image.name);
          }
        }

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        if (validImages.isNotEmpty) {
          setState(() => _pickedImages.addAll(validImages));
        }

        if (invalidImageNames.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Skipped ${invalidImageNames.length} invalid image(s): ${invalidImageNames.join(', ')}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

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

  Future<void> _takePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        // Show loading while validating
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Processing image...'),
                    ],
                  ),
                ),
          );
        }

        final isValid = await _validateImageFile(pickedFile);

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        if (isValid) {
          setState(() => _pickedImages.add(pickedFile));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid image captured. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

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

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  // Helper method to check if a file is a video
  bool _isVideoFile(XFile file) {
    final extension = file.path.toLowerCase().split('.').last;
    return extension == 'mp4' || extension == 'mov' || extension == 'avi';
  }

  // Show full-screen preview of selected media
  void _previewMedia(ImageProvider imageProvider, {bool isVideo = false}) {
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
                                        color: Colors.black.withValues(alpha: 0.5),
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
                                          color: Colors.black.withValues(alpha: 0.7),
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
                        color: Colors.black.withValues(alpha: 0.6),
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

  // Upload new images and return their URLs
  Future<List<String>> _uploadNewImages(String userId, String carId) async {
    final newImageUrls = <String>[];

    for (final imageFile in _pickedImages) {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final imageUrl = await _carService.uploadCarMedia(
        userId,
        carId,
        imageBytes,
      );
      newImageUrls.add(imageUrl);
    }

    return newImageUrls;
  }

  // Create a new car
  Future<void> _createCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final carId = _uuid.v4();

      // Upload new images
      final newImageUrls = await _uploadNewImages(userId, carId);

      final carData = Car(
        id: carId,
        ownerId: userId,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        mileage: double.parse(_mileageController.text).toInt(),
        location: _locationController.text.trim(),
        contact: _contactController.text.trim(),
        description: _descriptionController.text.trim(),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        forSale: _isForSale,
        isPublic: true,
        isAvailable: true,
        createdAt: DateTime.now(),
        mediaUrls: newImageUrls,
        salePrice:
            _isForSale ? double.tryParse(_salePriceController.text) : null,
        bookingRatePerDay:
            !_isForSale ? double.tryParse(_bookingRateController.text) : null,
      );

      await _carService.createCar(carData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car listed successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingCar == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Track which media URLs were removed
      final originalMediaUrls = _existingCar!.mediaUrls.toSet();
      final currentMediaUrls = _existingImageUrls.toSet();
      final removedMediaUrls =
          originalMediaUrls.difference(currentMediaUrls).toList();

      // Upload new images and combine with existing ones
      final newImageUrls = await _uploadNewImages(userId, _existingCar!.id);
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];

      final updatedCarData = Car(
        id: _existingCar!.id,
        ownerId: _existingCar!.ownerId,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        mileage: double.parse(_mileageController.text).toInt(),
        location: _locationController.text.trim(),
        contact: _contactController.text.trim(),
        description: _descriptionController.text.trim(),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        forSale: _isForSale,
        isPublic: _existingCar!.isPublic,
        isAvailable: _existingCar!.isAvailable,
        createdAt: _existingCar!.createdAt,
        mediaUrls: allImageUrls,
        salePrice:
            _isForSale ? double.tryParse(_salePriceController.text) : null,
        bookingRatePerDay:
            !_isForSale ? double.tryParse(_bookingRateController.text) : null,
      );

      // Update car with removed media cleanup
      await _carService.updateCar(
        updatedCarData,
        removedMediaUrls: removedMediaUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Main submit handler - delegates to create or update
  void _handleSubmit() {
    if (_isEditMode) {
      _updateCar();
    } else {
      _createCar();
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
    final isDriver = _userRole?.toLowerCase() == 'driver';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ScaffoldWithNav(
      title: _isEditMode ? 'Edit Car' : 'Add Car',
      currentRoute: '/cars/add',
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionCard(
                        context,
                        title: 'Listing Type',
                        children: [
                          _buildListingTypeToggle(
                            context,
                            isDriver: isDriver,
                            isForSale: _isForSale,
                            onChanged:
                                (value) => setState(() => _isForSale = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        context,
                        title: 'Car Details',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _makeController,
                                  labelText: 'Make *',
                                  hintText: 'e.g., Maruti',
                                  validator:
                                      (v) => _validateRequired(v, 'Make'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _modelController,
                                  labelText: 'Model *',
                                  hintText: 'e.g., Swift',
                                  validator:
                                      (v) => _validateRequired(v, 'Model'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _yearController,
                                  labelText: 'Year *',
                                  hintText: 'e.g., 2020',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Year is required';
                                    }
                                    final year = int.tryParse(value!);
                                    if (year == null ||
                                        year < 1980 ||
                                        year > DateTime.now().year + 1) {
                                      return 'Enter a valid year';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _mileageController,
                                  labelText: 'Mileage (km/l) *',
                                  hintText: 'e.g., 18.5',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d*'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) {
                                      return 'Mileage is required';
                                    }
                                    final mileage = double.tryParse(value!);
                                    if (mileage == null || mileage <= 0) {
                                      return 'Enter a valid mileage';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownFormField<FuelType>(
                            initialValue: _selectedFuelType,
                            labelText: 'Fuel Type *',
                            items:
                                FuelType.values
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) =>
                                    setState(() => _selectedFuelType = value!),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownFormField<Transmission>(
                            initialValue: _selectedTransmission,
                            labelText: 'Transmission *',
                            items:
                                Transmission.values
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type.name),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setState(
                                  () => _selectedTransmission = value!,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (_isForSale)
                            _buildTextFormField(
                              controller: _salePriceController,
                              labelText: 'Sale Price (₹) *',
                              hintText: 'e.g., 500000',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (_isForSale) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Price is required';
                                  }
                                  final price = double.tryParse(value!);
                                  if (price == null || price <= 0) {
                                    return 'Enter a valid price';
                                  }
                                }
                                return null;
                              },
                            )
                          else
                            _buildTextFormField(
                              controller: _bookingRateController,
                              labelText: 'Booking Rate (₹/Hour) *',
                              hintText: 'e.g., 2000',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (!_isForSale) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Rate is required';
                                  }
                                  final rate = double.tryParse(value!);
                                  if (rate == null || rate <= 0) {
                                    return 'Enter a valid rate';
                                  }
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _contactController,
                            labelText: 'Contact *',
                            hintText: 'e.g., 9876543210',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) => _validateRequired(v, 'Contact'),
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _locationController,
                            labelText: 'Location *',
                            hintText: 'e.g., Mumbai, Maharashtra',
                            validator: (v) => _validateRequired(v, 'Location'),
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            controller: _descriptionController,
                            labelText: 'Description (Optional)',
                            hintText: 'Additional details...',
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        context,
                        title: 'Images',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickImages,
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
                                  onPressed: _takePicture,
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
                                          () => _removeExistingImage(index),
                                    );
                                  }),
                                  // New picked images from local files
                                  ..._pickedImages.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final image = entry.value;
                                    return _buildImageThumbnail(
                                      imageProvider: FileImage(
                                        File(image.path),
                                      ),
                                      onRemove: () => _removeImage(index),
                                      file:
                                          image, // Pass the file to detect video type
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
                          onPressed: _isLoading ? null : _handleSubmit,
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
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _isEditMode ? 'Update Car' : 'Save Car',
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

  Widget _buildSectionCard(
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

  Widget _buildListingTypeToggle(
    BuildContext context, {
    required bool isDriver,
    required bool isForSale,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap:
                  isDriver
                      ? () {
                        if (isForSale) onChanged(false);
                      }
                      : null,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !isForSale ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'For Booking',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            !isForSale
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (!isDriver)
                      Text(
                        'Only drivers can list cars for bookings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 15,
                          color:
                              !isForSale
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap:
                  isDriver
                      ? () {
                        if (!isForSale) onChanged(true);
                      }
                      : null,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isForSale ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'For Sale',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        isForSale
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
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

  Widget _buildDropdownFormField<T>({
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

  // Enhanced image thumbnail with error handling and tap-to-view
  Widget _buildImageThumbnail({
    required ImageProvider imageProvider,
    required VoidCallback onRemove,
    XFile? file,
  }) {
    final isVideo = file != null && _isVideoFile(file);

    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      height: 100,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _previewMedia(imageProvider, isVideo: isVideo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Use FutureBuilder for better error handling with file images
                  file != null
                      ? FutureBuilder<bool>(
                        future: _validateImageFile(file),
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
                          }

                          if (snapshot.hasError || snapshot.data == false) {
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

                          return Image.file(
                            File(file.path),
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
                        image: imageProvider,
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
                  if (isVideo)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
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
                  // Tap indicator - only show for valid images
                  if (file == null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      color: Colors.black.withAlpha(50),
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