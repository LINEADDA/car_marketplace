import 'dart:convert';

class UserProfile {
  final String id;
  final String? avatarUrl;
  final String fullName;
  final String username;
  final String phoneNumber;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.avatarUrl,
    required this.fullName,
    required this.username,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  // A factory constructor for creating a new UserProfile instance from a map.
  // This is used when you fetch data from Supabase (which comes as a JSON map).
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      avatarUrl: map['avatar_url'] as String?, 
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      phoneNumber: map['phone_number'] as String,
      role: map['role'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // A method for converting a UserProfile instance into a map.
  // This is used when you want to send data to Supabase (e.g., for an update or insert).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'avatar_url': avatarUrl,
      'full_name': fullName,
      'username': username,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods for easy serialization/deserialization to/from JSON strings.
  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);

  // Optional: Override toString for better debugging output.
  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: $fullName, username: $username, role: $role)';
  }

  // Optional: copyWith method to easily create a modified copy of a profile.
  UserProfile copyWith({
    String? id,
    String? avatarUrl,
    String? fullName,
    String? username,
    String? phoneNumber,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
