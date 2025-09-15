import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/user_avatar.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile? profile;
  const EditProfilePage({super.key, this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final ProfileService _profileService;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    if (widget.profile != null) {
      _nameController.text = widget.profile!.fullName;
      _usernameController.text = widget.profile!.username;
      _phoneController.text = widget.profile!.phoneNumber;
      _avatarUrl = widget.profile!.avatarUrl;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        
        final updatedProfile = UserProfile(
          id: userId,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          avatarUrl: _avatarUrl,
          role: widget.profile?.role ?? 'user',
          isActive: widget.profile?.isActive ?? true,
          createdAt: widget.profile?.createdAt ?? DateTime.now(),
        );

        await _profileService.updateProfile(updatedProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const CustomAppBar(title: 'Edit Profile'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- CORRECTION ---
                      // The UserAvatar now correctly handles the avatar update logic internally.
                      // We pass the profile object and listen for a URL change via a callback.
                      UserAvatar(
                        profile: widget.profile,
                        radius: 60,
                        onAvatarUpdated: (newUrl) {
                          setState(() {
                            _avatarUrl = newUrl;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (value) => value!.isEmpty ? 'Full name cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                        validator: (value) => value!.isEmpty ? 'Username cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty ? 'Phone number cannot be empty' : null,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
      );
  }
}