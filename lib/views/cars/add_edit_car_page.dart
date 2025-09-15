import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/car.dart';
import '../../services/car_service.dart';
import '../../services/profile_service.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_app_bar.dart';

class AddEditCarPage extends StatefulWidget {
  final Car? carToEdit;
  const AddEditCarPage({super.key, this.carToEdit});

  @override
  State<AddEditCarPage> createState() => _AddEditCarPageState();
}

class _AddEditCarPageState extends State<AddEditCarPage> {
  final _formKey = GlobalKey<FormState>();
  late final CarService _carService;
  late final ProfileService _profileService;
  final _uuid = const Uuid();

  // --- Form Controllers ---
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _bookingRateController = TextEditingController();

  // --- State Variables ---
  FuelType _selectedFuelType = FuelType.petrol;
  Transmission _selectedTransmission = Transmission.automatic;
  bool _isForSale = false;
  final List<XFile> _pickedImages = [];
  late List<String> _existingImageUrls;
  bool _isLoading = true; // Start as loading to fetch role
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _carService = CarService(Supabase.instance.client);
    _profileService = ProfileService(Supabase.instance.client);
    _loadUserRoleAndInitForm();
  }

  Future<void> _loadUserRoleAndInitForm() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final profile = await _profileService.getProfile(userId);

    if (mounted) {
      setState(() {
        _userRole = profile?.role; // Store the user's role
        _existingImageUrls = List<String>.from(
          widget.carToEdit?.mediaUrls ?? [],
        );

        if (widget.carToEdit != null) {
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
        } else {
          // Default based on role if creating a new car
          _isForSale = _userRole != 'driver';
        }
        _isLoading = false; // Stop loading once role and data are set
      });
    }
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
    if (images.isNotEmpty) setState(() => _pickedImages.addAll(images));
  }

  Future<void> _saveCar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final carId = widget.carToEdit?.id ?? _uuid.v4();
      final updatedImageUrls = List<String>.from(_existingImageUrls);

      for (final imageFile in _pickedImages) {
        final imageUrl = await _carService.uploadCarMedia(
          userId,
          carId,
          File(imageFile.path),
        );
        updatedImageUrls.add(imageUrl);
      }

      final carData = Car(
        id: carId,
        ownerId: userId,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        mileage: int.parse(_mileageController.text),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        forSale:
            _userRole == 'user'
                ? true
                : _isForSale, // Force 'true' for 'user' role
        isPublic: true,
        isAvailable: widget.carToEdit?.isAvailable ?? true,
        createdAt: widget.carToEdit?.createdAt ?? DateTime.now(),
        mediaUrls: updatedImageUrls,
        salePrice:
            _isForSale ? double.tryParse(_salePriceController.text) : null,
        bookingRatePerDay:
            !_isForSale ? double.tryParse(_bookingRateController.text) : null,
      );

      widget.carToEdit == null
          ? await _carService.createCar(carData)
          : await _carService.updateCar(carData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Car saved successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: widget.carToEdit == null ? 'Add Car' : 'Edit Car',
        ),
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
                        TextFormField(
                          controller: _makeController,
                          decoration: const InputDecoration(labelText: 'Make'),
                          validator:
                              (v) => Validators.validateNotEmpty(v, 'Make'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(labelText: 'Model'),
                          validator:
                              (v) => Validators.validateNotEmpty(v, 'Model'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _yearController,
                          decoration: const InputDecoration(labelText: 'Year'),
                          keyboardType: TextInputType.number,
                          validator:
                              (v) => Validators.validateNotEmpty(v, 'Year'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mileageController,
                          decoration: const InputDecoration(
                            labelText: 'Mileage',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (v) => Validators.validateNotEmpty(v, 'Mileage'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                          validator:
                              (v) => Validators.validateNotEmpty(v, 'Location'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // --- Conditional UI for Listing Type ---
                        if (_userRole == 'driver' || _userRole == 'admin')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('For Sale'),
                              Switch(
                                value: !_isForSale,
                                onChanged:
                                    (v) => setState(() => _isForSale = !v),
                              ),
                              const Text('For Booking'),
                            ],
                          )
                        else if (_userRole == 'user')
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('Listing cars for sale only'),
                              subtitle: Text(
                                'Your account type is set to list cars for sale.',
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        if (_isForSale)
                          TextFormField(
                            controller: _salePriceController,
                            decoration: const InputDecoration(
                              labelText: 'Sale Price (\$)',
                            ),
                            keyboardType: TextInputType.number,
                            validator:
                                (v) => Validators.validateNotEmpty(v, 'Price'),
                          )
                        else
                          TextFormField(
                            controller: _bookingRateController,
                            decoration: const InputDecoration(
                              labelText: 'Booking Rate (\$/day)',
                            ),
                            keyboardType: TextInputType.number,
                            validator:
                                (v) => Validators.validateNotEmpty(v, 'Rate'),
                          ),

                        const SizedBox(height: 16),
                        DropdownButtonFormField<FuelType>(
                          initialValue: _selectedFuelType,
                          decoration: const InputDecoration(
                            labelText: 'Fuel Type',
                          ),
                          items:
                              FuelType.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.name.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedFuelType = v!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Transmission>(
                          initialValue: _selectedTransmission,
                          decoration: const InputDecoration(
                            labelText: 'Transmission',
                          ),
                          items:
                              Transmission.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.name.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (v) => setState(() => _selectedTransmission = v!),
                        ),
                        const SizedBox(height: 24),

                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Add Photos'),
                        ),

                        if (_existingImageUrls.isNotEmpty ||
                            _pickedImages.isNotEmpty)
                          Container(
                            height: 100,
                            margin: const EdgeInsets.only(top: 16),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ..._existingImageUrls.map(
                                  (url) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.network(
                                      url,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                ..._pickedImages.map(
                                  (file) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Image.file(
                                      File(file.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveCar,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: const Text('Save Car'),
                        ),
                      ],
                    ),
                  ),
                ),
      );
  }
}
