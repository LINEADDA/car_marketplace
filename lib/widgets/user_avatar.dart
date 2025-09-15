import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/user_profile.dart';
import '../utils/helpers.dart';

class UserAvatar extends StatefulWidget {
  final UserProfile? profile; // Now accepts a nullable profile
  final double radius;
  final void Function(String)? onAvatarUpdated; // Callback to notify parent of new URL

  const UserAvatar({
    super.key,
    this.profile,
    this.radius = 24.0,
    this.onAvatarUpdated,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _isLoading = false;

  Future<void> _uploadAvatar() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final file = File(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$userId/$fileName';

      // Upload to storage
      await Supabase.instance.client.storage.from('avatars').upload(filePath, file);

      // Get public URL
      final imageUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(filePath);

      // Notify the parent widget of the new URL
      if (widget.onAvatarUpdated != null) {
        widget.onAvatarUpdated!(imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading avatar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle the case where the profile might be null (e.g., a new user)
    if (widget.profile == null) {
      return CircleAvatar(
        radius: widget.radius,
        child: Icon(Icons.person, size: widget.radius),
      );
    }

    final hasAvatar = widget.profile!.avatarUrl != null && widget.profile!.avatarUrl!.isNotEmpty;

    return InkWell(
      onTap: _isLoading ? null : _uploadAvatar,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: hasAvatar ? NetworkImage(widget.profile!.avatarUrl!) : null,
            child: !hasAvatar
                ? Text(
                    Helpers.getInitials(widget.profile!.fullName),
                    style: TextStyle(
                      fontSize: widget.radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (widget.onAvatarUpdated != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: widget.radius * 0.3,
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Icon(Icons.edit, size: widget.radius * 0.3, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}