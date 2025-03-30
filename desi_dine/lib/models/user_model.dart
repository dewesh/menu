import 'package:cloud_firestore/cloud_firestore.dart';

/// Main user model representing basic user information
class User {
  final String userId;
  final String? name;
  final String? email;
  final DateTime createdAt;
  final DateTime lastModified;
  final SystemPreferences systemPreferences;

  User({
    required this.userId,
    this.name,
    this.email,
    required this.createdAt,
    required this.lastModified,
    required this.systemPreferences,
  });

  /// Convert User object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
      'systemPreferences': systemPreferences.toMap(),
    };
  }

  /// Create User object from Firestore document
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'] as String,
      name: map['name'] as String?,
      email: map['email'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: (map['lastModified'] as Timestamp).toDate(),
      systemPreferences: SystemPreferences.fromMap(map['systemPreferences']),
    );
  }

  /// Create a copy of User with modified fields
  User copyWith({
    String? userId,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? lastModified,
    SystemPreferences? systemPreferences,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      systemPreferences: systemPreferences ?? this.systemPreferences,
    );
  }
}

/// System preferences for the user (theme, notifications, etc.)
class SystemPreferences {
  final String themeMode; // 'light' or 'dark'
  final bool notificationsEnabled;
  final bool isDarkMode; // Convenience field that maps to themeMode='dark'
  final int familySize;
  final List<String> dietaryPreferences;
  final List<String> cuisinePreferences;
  final List<FamilyMember> familyMembers;

  SystemPreferences({
    this.themeMode = 'light',
    this.notificationsEnabled = true,
    bool? isDarkMode,
    this.familySize = 1,
    this.dietaryPreferences = const [],
    this.cuisinePreferences = const [],
    this.familyMembers = const [],
  }) : this.isDarkMode = isDarkMode ?? (themeMode == 'dark');

  /// Convert SystemPreferences object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'isDarkMode': isDarkMode,
      'familySize': familySize,
      'dietaryPreferences': dietaryPreferences,
      'cuisinePreferences': cuisinePreferences,
      'familyMembers': familyMembers.map((member) => member.toMap()).toList(),
    };
  }

  /// Create SystemPreferences object from Firestore document
  factory SystemPreferences.fromMap(Map<String, dynamic> map) {
    return SystemPreferences(
      themeMode: map['themeMode'] as String? ?? 'light',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      familySize: map['familySize'] as int? ?? 1,
      dietaryPreferences: List<String>.from(map['dietaryPreferences'] as List? ?? []),
      cuisinePreferences: List<String>.from(map['cuisinePreferences'] as List? ?? []),
      familyMembers: map['familyMembers'] != null
          ? List<FamilyMember>.from(
              (map['familyMembers'] as List).map((x) => FamilyMember.fromMap(x)))
          : [],
    );
  }
}

/// User dietary and cuisine preferences
class UserPreferences {
  final String userId;
  final String dietaryType; // From predefined list (vegetarian, non-vegetarian, etc.)
  final List<CustomPreference> customDietaryPreferences;
  final List<CuisinePreference> cuisinePreferences;
  final TastePreferences tastePreferences;
  final List<String> avoidedIngredients;

  UserPreferences({
    required this.userId,
    required this.dietaryType,
    this.customDietaryPreferences = const [],
    this.cuisinePreferences = const [],
    required this.tastePreferences,
    this.avoidedIngredients = const [],
  });

  /// Convert UserPreferences object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dietaryType': dietaryType,
      'customDietaryPreferences': customDietaryPreferences.map((x) => x.toMap()).toList(),
      'cuisinePreferences': cuisinePreferences.map((x) => x.toMap()).toList(),
      'tastePreferences': tastePreferences.toMap(),
      'avoidedIngredients': avoidedIngredients,
    };
  }

  /// Create UserPreferences object from Firestore document
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      userId: map['userId'] as String,
      dietaryType: map['dietaryType'] as String,
      customDietaryPreferences: List<CustomPreference>.from(
        (map['customDietaryPreferences'] as List?)?.map(
              (x) => CustomPreference.fromMap(x),
            ) ??
            [],
      ),
      cuisinePreferences: List<CuisinePreference>.from(
        (map['cuisinePreferences'] as List?)?.map(
              (x) => CuisinePreference.fromMap(x),
            ) ??
            [],
      ),
      tastePreferences: TastePreferences.fromMap(map['tastePreferences']),
      avoidedIngredients:
          List<String>.from(map['avoidedIngredients'] as List? ?? []),
    );
  }
}

/// Custom dietary preference defined by the user
class CustomPreference {
  final String name;
  final String description;

  CustomPreference({
    required this.name,
    required this.description,
  });

  /// Convert CustomPreference object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  /// Create CustomPreference object from Firestore document
  factory CustomPreference.fromMap(Map<String, dynamic> map) {
    return CustomPreference(
      name: map['name'] as String,
      description: map['description'] as String,
    );
  }
}

/// Cuisine preference with frequency indication
class CuisinePreference {
  final String cuisineType;
  final String frequencyPreference; // daily, weekly, occasionally, rarely

  CuisinePreference({
    required this.cuisineType,
    required this.frequencyPreference,
  });

  /// Convert CuisinePreference object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'cuisineType': cuisineType,
      'frequencyPreference': frequencyPreference,
    };
  }

  /// Create CuisinePreference object from Firestore document
  factory CuisinePreference.fromMap(Map<String, dynamic> map) {
    return CuisinePreference(
      cuisineType: map['cuisineType'] as String,
      frequencyPreference: map['frequencyPreference'] as String,
    );
  }
}

/// Taste preferences for the user (spice level, sweetness, etc.)
class TastePreferences {
  final int spiceLevel; // 1-5 scale
  final int sweetness; // 1-5 scale
  final int sourness; // 1-5 scale

  TastePreferences({
    required this.spiceLevel,
    required this.sweetness,
    required this.sourness,
  });

  /// Convert TastePreferences object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'spiceLevel': spiceLevel,
      'sweetness': sweetness,
      'sourness': sourness,
    };
  }

  /// Create TastePreferences object from Firestore document
  factory TastePreferences.fromMap(Map<String, dynamic> map) {
    return TastePreferences(
      spiceLevel: map['spiceLevel'] as int? ?? 3,
      sweetness: map['sweetness'] as int? ?? 3,
      sourness: map['sourness'] as int? ?? 3,
    );
  }
}

/// Family member model with individual preferences
class FamilyMember {
  final String userId; // Reference to parent user
  final String memberId;
  final String name;
  final int? age;
  final String relationship; // self, spouse, child, etc.
  final FamilyMemberDietaryPreferences dietaryPreferences;
  final List<HealthCondition> healthConditions;
  final List<String> avoidedIngredients;
  final List<String> dietaryRestrictions; // For simplified test usage

  FamilyMember({
    this.userId = '',
    this.memberId = '',
    required this.name,
    this.age,
    this.relationship = 'self',
    FamilyMemberDietaryPreferences? dietaryPreferences,
    this.healthConditions = const [],
    this.avoidedIngredients = const [],
    List<String>? dietaryRestrictions,
  }) : 
    this.dietaryPreferences = dietaryPreferences ?? FamilyMemberDietaryPreferences(dietaryType: 'standard'),
    this.dietaryRestrictions = dietaryRestrictions ?? [];

  /// Convert FamilyMember object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'memberId': memberId,
      'name': name,
      'age': age,
      'relationship': relationship,
      'dietaryPreferences': dietaryPreferences.toMap(),
      'healthConditions': healthConditions.map((x) => x.toMap()).toList(),
      'avoidedIngredients': avoidedIngredients,
      'dietaryRestrictions': dietaryRestrictions,
    };
  }

  /// Create FamilyMember object from Firestore document
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      userId: map['userId'] as String? ?? '',
      memberId: map['memberId'] as String? ?? '',
      name: map['name'] as String,
      age: map['age'] as int?,
      relationship: map['relationship'] as String? ?? 'self',
      dietaryPreferences: map['dietaryPreferences'] != null
          ? FamilyMemberDietaryPreferences.fromMap(map['dietaryPreferences'])
          : null,
      healthConditions: map['healthConditions'] != null
          ? List<HealthCondition>.from(
              (map['healthConditions'] as List).map(
                (x) => HealthCondition.fromMap(x),
              ),
            )
          : [],
      avoidedIngredients:
          List<String>.from(map['avoidedIngredients'] as List? ?? []),
      dietaryRestrictions:
          List<String>.from(map['dietaryRestrictions'] as List? ?? []),
    );
  }
}

/// Dietary preferences for a family member
class FamilyMemberDietaryPreferences {
  final String dietaryType;
  final List<String> customDietaryPreferences;

  FamilyMemberDietaryPreferences({
    required this.dietaryType,
    this.customDietaryPreferences = const [],
  });

  /// Convert FamilyMemberDietaryPreferences object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'dietaryType': dietaryType,
      'customDietaryPreferences': customDietaryPreferences,
    };
  }

  /// Create FamilyMemberDietaryPreferences object from Firestore document
  factory FamilyMemberDietaryPreferences.fromMap(Map<String, dynamic> map) {
    return FamilyMemberDietaryPreferences(
      dietaryType: map['dietaryType'] as String,
      customDietaryPreferences:
          List<String>.from(map['customDietaryPreferences'] as List? ?? []),
    );
  }
}

/// Health condition model for family members
class HealthCondition {
  final String condition; // diabetes, hypertension, etc.
  final String severity; // mild, moderate, severe
  final String? dietaryNotes;

  HealthCondition({
    required this.condition,
    required this.severity,
    this.dietaryNotes,
  });

  /// Convert HealthCondition object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'severity': severity,
      'dietaryNotes': dietaryNotes,
    };
  }

  /// Create HealthCondition object from Firestore document
  factory HealthCondition.fromMap(Map<String, dynamic> map) {
    return HealthCondition(
      condition: map['condition'] as String,
      severity: map['severity'] as String,
      dietaryNotes: map['dietaryNotes'] as String?,
    );
  }
} 