import 'dart:io';
import 'package:flutter/material.dart';
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

  // Form controllers
  final _nameController = TextEditingController();
  final _pricingController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();

  // State variables for services and images
  List<ShopService> _services = [];
  final List<XFile> _pickedImages = []; // To hold newly picked images
  late List<String> _existingImageUrls; // To hold URLs of already uploaded images
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
    // ... (This function remains unchanged, so it's omitted for brevity)
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
                  TextFormField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name'), validator: (v) => Validators.validateNotEmpty(v, 'Name')),
                  TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                  TextFormField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
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

        // Now upload images and update the record
        if (_pickedImages.isNotEmpty) {
          final imageUrls = <String>[];
          for (final imageFile in _pickedImages) {
            final imageUrl = await _repairShopService.uploadShopMediaFile(userId, newShopId, File(imageFile.path));
            imageUrls.add(imageUrl);
          }
          await _repairShopService.updateShopMedia(newShopId, imageUrls);
        }
      } else {
        // --- UPDATE EXISTING SHOP ---
        final shop = widget.shopToEdit!;
        final updatedImageUrls = List<String>.from(_existingImageUrls);

        // Upload any newly picked images
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
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic Shop Fields
                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Shop Name'), validator: (v) => Validators.validateNotEmpty(v, 'Name')),
                      TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location'), validator: (v) => Validators.validateNotEmpty(v, 'Location')),
                      TextFormField(controller: _contactController, decoration: const InputDecoration(labelText: 'Contact Number'), keyboardType: TextInputType.phone, validator: Validators.validatePhoneNumber),
                      TextFormField(controller: _pricingController, decoration: const InputDecoration(labelText: 'General Pricing Info')),
                      
                      const SizedBox(height: 16),
                      // Image Upload Section
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add Shop Photos'),
                      ),
                      if (_existingImageUrls.isNotEmpty || _pickedImages.isNotEmpty)
                        Container(
                          height: 100,
                          margin: const EdgeInsets.only(top: 16),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._existingImageUrls.map((url) => Padding(padding: const EdgeInsets.only(right: 8.0), child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover))),
                              ..._pickedImages.map((file) => Padding(padding: const EdgeInsets.only(right: 8.0), child: Image.file(File(file.path), width: 100, height: 100, fit: BoxFit.cover))),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),
                      const Divider(),

                      // Services Management Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Services', style: Theme.of(context).textTheme.titleLarge),
                          IconButton(icon: const Icon(Icons.add_circle), onPressed: () => _showServiceDialog()),
                        ],
                      ),
                      if (_services.isEmpty)
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Text('No services added yet. Tap the + icon to add one.'))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return Card(
                              child: ListTile(
                                title: Text(service.name),
                                subtitle: service.price != null ? Text('\$${service.price}') : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showServiceDialog(serviceToEdit: service)),
                                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _services.removeAt(index))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: _saveShop, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)), child: const Text('Save Shop')),
                    ],
                  ),
                ),
              ),
      );
  }
}