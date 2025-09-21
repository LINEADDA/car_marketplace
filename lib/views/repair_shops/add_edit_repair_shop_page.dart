import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/repair_shop.dart';
import '../../services/repair_shop_service.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_app_bar.dart';

class AddEditRepairShopPage extends StatefulWidget {
  final RepairShop? shopToEdit;

  const AddEditRepairShopPage({super.key, this.shopToEdit});

  @override
  State<AddEditRepairShopPage> createState() => _AddEditRepairShopPageState();
}

class _AddEditRepairShopPageState extends State<AddEditRepairShopPage> {
  final _formKey = GlobalKey<FormState>();
  late final RepairShopService _repairShopService;
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _pricingController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();

  List<ShopService> _services = [];
  final List<XFile> _pickedImages = []; 
  late List<String> _existingImageUrls; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repairShopService = RepairShopService(Supabase.instance.client);
    _existingImageUrls = List<String>.from(widget.shopToEdit?.mediaUrls ?? []);
    _services = List<ShopService>.from(widget.shopToEdit?.services ?? []);

    if (widget.shopToEdit != null) {
      final shop = widget.shopToEdit!;
      _nameController.text = shop.name;
      _pricingController.text = shop.pricingInfo;
      _locationController.text = shop.location;
      _contactController.text = shop.contactNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pricingController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images);
      });
    }
  }

  Future<void> _showServiceDialog({ShopService? serviceToEdit}) async {
    final serviceFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: serviceToEdit?.name);
    final descCtrl = TextEditingController(text: serviceToEdit?.description);
    final priceCtrl = TextEditingController(text: serviceToEdit?.price?.toString() ?? '');

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
                    decoration: InputDecoration(
                      labelText: 'Service Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (v) => Validators.validateNotEmpty(v, 'Service Name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: InputDecoration(
                      labelText: 'Price (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
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
              child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                if (serviceFormKey.currentState!.validate()) {
                  final newService = ShopService(
                    id: serviceToEdit?.id ?? _uuid.v4(),
                    name: nameCtrl.text,
                    description: descCtrl.text,
                    price: double.tryParse(priceCtrl.text),
                    mediaUrls: serviceToEdit?.mediaUrls ?? [],
                  );
                  Navigator.of(context).pop(newService);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
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

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      if (widget.shopToEdit == null) {
        // --- CREATE NEW SHOP ---
        final newShopData = {
          'owner_id': userId,
          'name': _nameController.text.trim(),
          'pricing_info': _pricingController.text.trim(),
          'location': _locationController.text.trim(),
          'contact_number': _contactController.text.trim(),
          'media_urls': <String>[],
          'services': _services.map((s) => s.toMap()).toList(),
        };
        final createdShop = await _repairShopService.createRepairShop(newShopData);
        final newShopId = createdShop['id'] as String;

        if (_pickedImages.isNotEmpty) {
          final imageUrls = <String>[];
          for (final imageFile in _pickedImages) {
            final imageUrl = await _repairShopService.uploadShopMediaFile(userId, newShopId, File(imageFile.path));
            imageUrls.add(imageUrl);
          }
          await _repairShopService.updateShopMedia(newShopId, imageUrls);
        }
      } else {
        final shop = widget.shopToEdit!;
        final updatedImageUrls = List<String>.from(_existingImageUrls);

        for (final imageFile in _pickedImages) {
          final imageUrl = await _repairShopService.uploadShopMediaFile(userId, shop.id, File(imageFile.path));
          updatedImageUrls.add(imageUrl);
        }

        final shopData = RepairShop(
          id: shop.id,
          ownerId: userId,
          name: _nameController.text.trim(),
          pricingInfo: _pricingController.text.trim(),
          location: _locationController.text.trim(),
          contactNumber: _contactController.text.trim(),
          mediaUrls: updatedImageUrls,
          createdAt: shop.createdAt,
          services: _services,
        );
        await _repairShopService.updateRepairShop(shopData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop saved successfully!')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving shop: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.shopToEdit == null ? 'Add Shop' : 'Edit Shop'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section: Basic Shop Fields
                    const Text('Shop Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Shop Name *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (v) => Validators.validateNotEmpty(v, 'Shop Name'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (v) => Validators.validateNotEmpty(v, 'Location'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhoneNumber,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pricingController,
                      decoration: InputDecoration(
                        labelText: 'General Pricing Info (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),
                    // Section: Image Upload
                    const Text('Shop Photos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add Shop Photos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[50],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                    if (_existingImageUrls.isNotEmpty || _pickedImages.isNotEmpty)
                      Container(
                        height: 100,
                        margin: const EdgeInsets.only(top: 16),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._existingImageUrls.map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            ..._pickedImages.map(
                              (file) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(file.path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    // Section: Services Management
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                          onPressed: () => _showServiceDialog(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_services.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No services added yet. Tap the + icon to add one.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: service.price != null ? Text('\$${service.price}', style: const TextStyle(color: Colors.green)) : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                    onPressed: () => _showServiceDialog(serviceToEdit: service),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => setState(() => _services.removeAt(index)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        widget.shopToEdit == null ? 'Save Shop' : 'Update Shop',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}