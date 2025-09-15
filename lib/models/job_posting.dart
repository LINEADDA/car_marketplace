import 'dart:convert';

class JobPosting {
  final String id;
  final String ownerId;
  final String? shopId;
  final String jobTitle;
  final String jobType;
  final String? jobDescription;
  final String location;
  final String contactNumber;
  final bool isActive;
  final DateTime createdAt;

  JobPosting({
    required this.id,
    required this.ownerId,
    this.shopId,
    required this.jobTitle,
    required this.jobType,
    this.jobDescription,
    required this.location,
    required this.contactNumber,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'shop_id': shopId,
      'job_title': jobTitle,
      'job_type': jobType,
      'job_description': jobDescription,
      'location': location,
      'contact_number': contactNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory JobPosting.fromMap(Map<String, dynamic> map) {
    return JobPosting(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      shopId: map['shop_id'] as String?,
      jobTitle: map['job_title'] as String,
      jobType: map['job_type'] as String,
      jobDescription: map['job_description'] as String?,
      location: map['location'] as String,
      contactNumber: map['contact_number'] as String,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory JobPosting.fromJson(String source) => JobPosting.fromMap(json.decode(source));

  // Helper method to create a modified copy of a JobPosting instance.
  // This is crucial for updating the state immutably in the UI.
  JobPosting copyWith({
    String? id,
    String? ownerId,
    String? shopId,
    String? jobTitle,
    String? jobType,
    String? jobDescription,
    String? location,
    String? contactNumber,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return JobPosting(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      shopId: shopId ?? this.shopId,
      jobTitle: jobTitle ?? this.jobTitle,
      jobType: jobType ?? this.jobType,
      jobDescription: jobDescription ?? this.jobDescription,
      location: location ?? this.location,
      contactNumber: contactNumber ?? this.contactNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
