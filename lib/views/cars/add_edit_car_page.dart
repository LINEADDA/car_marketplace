import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../widgets/app_scaffold_with_nav.dart';

class AddEditCarPage extends StatefulWidget {
  final String? carId;
  final Car? carToEdit;
  final String? initialListingType;

  const AddEditCarPage({
    super.key,
    this.carId,
    this.carToEdit,
    this.initialListingType,
  });

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
  final _descriptionController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _bookingRateController = TextEditingController();

  FuelType _selectedFuelType = FuelType.petrol;
  Transmission _selectedTransmission = Transmission.manual;
  bool _isForSale = true;
  String? _userRole;

  final List<XFile> _pickedImages = [];
  late List<String> _existingImageUrls;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _fetchUserRole();

    if (widget.initialListingType != null) {
      _isForSale = widget.initialListingType == 'sale';
    }

    _existingImageUrls = List.from(widget.carToEdit?.mediaUrls ?? []);

    if (widget.carToEdit != null) {
      _populateFields();
    }
  }

  Future<void> _fetchUserRole() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isForSale = true);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _userRole = response['role'] as String?;
          if (_userRole?.toLowerCase() != 'driver') {
            _isForSale = true;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isForSale = true);
    }
  }

  void _populateFields() {
    final car = widget.carToEdit!;
    _makeController.text = car.make;
    _modelController.text = car.model;
    _yearController.text = car.year.toString();
    _mileageController.text = car.mileage.toString();
    _locationController.text = car.location;
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
    _descriptionController.dispose();
    _salePriceController.dispose();
    _bookingRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() => _pickedImages.addAll(images));
    }
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _pickedImages.add(pickedFile));
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final carId = widget.carToEdit?.id ?? _uuid.v4();
      final updatedImageUrls = List<String>.from(_existingImageUrls);

      for (final imageFile in _pickedImages) {
        final imageUrl = await _carService.uploadCarMedia(userId, carId, File(imageFile.path));
        updatedImageUrls.add(imageUrl);
      }

      final carData = Car(
        id: carId,
        ownerId: userId,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        mileage: double.parse(_mileageController.text).toInt(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        forSale: _isForSale,
        isPublic: true,
        isAvailable: widget.carToEdit?.isAvailable ?? true,
        createdAt: widget.carToEdit?.createdAt ?? DateTime.now(),
        mediaUrls: updatedImageUrls,
        salePrice: _isForSale ? double.tryParse(_salePriceController.text) : null,
        bookingRatePerDay: !_isForSale ? double.tryParse(_bookingRateController.text) : null,
      );

      if (widget.carToEdit == null) {
        await _carService.createCar(carData);
      } else {
        await _carService.updateCar(carData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.carToEdit != null ? 'Car updated successfully!' : 'Car listed successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final isEditing = widget.carToEdit != null;

    return ScaffoldWithNav(
      title: isEditing ? 'Edit Car' : 'Add Car',
      currentRoute: '/cars/add',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Listing Type', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('For Booking'),
                                Switch(
                                  value: _isForSale, 
                                  onChanged: isDriver
                                      ? (value) {
                                          setState(() => _isForSale = value);
                                        }
                                      : null, 
                                ),
                                const Text('For Sale'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Car Details', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 16),
                             Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _makeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Make *',
                                      hintText: 'e.g., Maruti',
                                    ),
                                    validator: (v) => _validateRequired(v, 'Make'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _modelController,
                                    decoration: const InputDecoration(
                                      labelText: 'Model *',
                                      hintText: 'e.g., Swift',
                                    ),
                                    validator: (v) => _validateRequired(v, 'Model'),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _yearController,
                                    decoration: const InputDecoration(
                                      labelText: 'Year *',
                                      hintText: 'e.g., 2020',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Year is required';
                                      final year = int.tryParse(value!);
                                      if (year == null || year < 1980 || year > DateTime.now().year + 1) {
                                        return 'Enter a valid year';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _mileageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Mileage (km/l) *',
                                      hintText: 'e.g., 18.5',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Mileage is required';
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
                            DropdownButtonFormField<FuelType>(
                              initialValue: _selectedFuelType,
                              decoration: const InputDecoration(labelText: 'Fuel Type *'),
                              items: FuelType.values
                                  .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedFuelType = value!),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Transmission>(
                              initialValue: _selectedTransmission,
                              decoration: const InputDecoration(labelText: 'Transmission *'),
                              items: Transmission.values
                                  .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedTransmission = value!),
                            ),
                            const SizedBox(height: 16),

                            if (_isForSale)
                              TextFormField(
                                controller: _salePriceController,
                                decoration: const InputDecoration(labelText: 'Sale Price (₹) *', hintText: 'e.g., 500000'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_isForSale) { 
                                    if (value?.isEmpty ?? true) return 'Price is required';
                                    final price = double.tryParse(value!);
                                    if (price == null || price <= 0) return 'Enter a valid price';
                                  }
                                  return null;
                                },
                              )
                            else
                              TextFormField(
                                controller: _bookingRateController,
                                decoration: const InputDecoration(labelText: 'Booking Rate (₹/day) *', hintText: 'e.g., 2000'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (!_isForSale) { 
                                    if (value?.isEmpty ?? true) return 'Rate is required';
                                    final rate = double.tryParse(value!);
                                    if (rate == null || rate <= 0) return 'Enter a valid rate';
                                  }
                                  return null;
                                },
                              ),
                            
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(labelText: 'Location *', hintText: 'e.g., Mumbai, Maharashtra'),
                              validator: (v) => _validateRequired(v, 'Location'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(labelText: 'Description (Optional)', hintText: 'Additional details...'),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                              'Images',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                             Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Choose from Gallery'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _takePicture,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Take Photo'),
                                  ),
                                ),
                              ],
                            ),
                             const SizedBox(height: 16),
                             if (_existingImageUrls.isNotEmpty || _pickedImages.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    ..._existingImageUrls.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final url = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                url,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeExistingImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                     ..._pickedImages.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final image = entry.value;
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(image.path),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(4),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(isEditing ? 'Update Car' : 'List Car'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}