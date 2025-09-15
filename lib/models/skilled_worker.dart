import 'dart:convert';

class SkilledWorker {
  final String id;
  final String ownerId;
  final String fullName;
  final String primarySkill;
  final String? experienceHeadline;
  final String location;
  final String contactNumber;
  final bool isAvailable;
  final DateTime createdAt;

  SkilledWorker({
    required this.id,
    required this.ownerId,
    required this.fullName,
    required this.primarySkill,
    this.experienceHeadline,
    required this.location,
    required this.contactNumber,
    required this.isAvailable,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': fullName,
      'primary_skill': primarySkill,
      'experience_headline': experienceHeadline,
      'location': location,
      'contact_number': contactNumber,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SkilledWorker.fromMap(Map<String, dynamic> map) {
    return SkilledWorker(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      fullName: map['full_name'] as String,
      primarySkill: map['primary_skill'] as String,
      experienceHeadline: map['experience_headline'] as String?,
      location: map['location'] as String,
      contactNumber: map['contact_number'] as String,
      isAvailable: map['is_available'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory SkilledWorker.fromJson(String source) => SkilledWorker.fromMap(json.decode(source));
}