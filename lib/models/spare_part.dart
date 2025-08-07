// Defines the possible conditions of a spare part using lowerCamelCase.
enum SparePartCondition {
  brandNew,
  usedLikeNew,
  usedGood,
  forParts,
  other,
}

// Extension to handle mapping between Dart enum and database string values.
extension SparePartConditionX on SparePartCondition {
  /// Converts the enum to the snake_case string format for the database.
  String toDbValue() {
    switch (this) {
      case SparePartCondition.brandNew:
        return 'brand_new';
      case SparePartCondition.usedLikeNew:
        return 'used_like_new';
      case SparePartCondition.usedGood:
        return 'used_good';
      case SparePartCondition.forParts:
        return 'for_parts';
      case SparePartCondition.other:
        return 'other';
    }
  }

  /// Creates an enum value from a database string.
  static SparePartCondition fromDbValue(String? value) {
    switch (value) {
      case 'brand_new':
        return SparePartCondition.brandNew;
      case 'used_like_new':
        return SparePartCondition.usedLikeNew;
      case 'used_good':
        return SparePartCondition.usedGood;
      case 'for_parts':
        return SparePartCondition.forParts;
      default:
        return SparePartCondition.other;
    }
  }
}

class SparePart {
  final String id;
  final List<String> mediaUrls;
  final String ownerId;
  final String title;
  final String description;
  final SparePartCondition condition;
  final DateTime createdAt;

  SparePart({
    required this.id,
    required this.mediaUrls,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.condition,
    required this.createdAt,
  });

  /// Creates a SparePart object from a Supabase record (Map).
  factory SparePart.fromMap(Map<String, dynamic> map) {
    return SparePart(
      id: map['id'] as String,
      mediaUrls: List<String>.from(map['media_urls'] as List),
      ownerId: map['owner_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      condition: SparePartConditionX.fromDbValue(map['condition']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts a SparePart object into a Map for inserting or updating in Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'media_urls': mediaUrls,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'condition': condition.toDbValue(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
