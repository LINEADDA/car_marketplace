import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../utils/helpers.dart';

class UserAvatar extends StatelessWidget {
  final UserProfile profile;
  final double radius;

  // The only change is here in the constructor:
  const UserAvatar({
    super.key, // Use the super parameter for the key.
    required this.profile,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    // The build method remains exactly the same.
    final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
      child: !hasAvatar
          ? Text(
              Helpers.getInitials(profile.fullName),
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
