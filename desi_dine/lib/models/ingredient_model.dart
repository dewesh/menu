import 'package:cloud_firestore/cloud_firestore.dart';

/// Ingredient model representing a food ingredient
class Ingredient {
  final String ingredientId;
  final String name;
  final String category; // vegetable, spice, grain, etc.
  final String? imageUrl;
  final String? description;
  final IngredientNutritionalInfo? nutritionalInfo;
  final PurchaseInfo? purchaseInfo;
  final List<String> tags; // common tags like 'vegan', 'gluten-free', etc.
  final List<String> commonAllergens; // common allergens like 'nuts', 'dairy', etc.
  final List<String> substitutes; // IDs of ingredients that can substitute this one
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final DateTime createdAt;
  final DateTime lastModified;

  Ingredient({
    required this.ingredientId,
    required this.name,
    required this.category,
    this.imageUrl,
    this.description,
    this.nutritionalInfo,
    this.purchaseInfo,
    this.tags = const [],
    this.commonAllergens = const [],
    this.substitutes = const [],
    this.isVegetarian = true,
    this.isVegan = false,
    this.isGlutenFree = true,
    required this.createdAt,
    required this.lastModified,
  });

  /// Convert Ingredient object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'description': description,
      'nutritionalInfo': nutritionalInfo?.toMap(),
      'purchaseInfo': purchaseInfo?.toMap(),
      'tags': tags,
      'commonAllergens': commonAllergens,
      'substitutes': substitutes,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
    };
  }

  /// Create Ingredient object from Firestore document
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      ingredientId: map['ingredientId'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      nutritionalInfo: map['nutritionalInfo'] != null
          ? IngredientNutritionalInfo.fromMap(map['nutritionalInfo'])
          : null,
      purchaseInfo: map['purchaseInfo'] != null
          ? PurchaseInfo.fromMap(map['purchaseInfo'])
          : null,
      tags: List<String>.from(map['tags'] as List? ?? []),
      commonAllergens: List<String>.from(map['commonAllergens'] as List? ?? []),
      substitutes: List<String>.from(map['substitutes'] as List? ?? []),
      isVegetarian: map['isVegetarian'] as bool? ?? true,
      isVegan: map['isVegan'] as bool? ?? false,
      isGlutenFree: map['isGlutenFree'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: (map['lastModified'] as Timestamp).toDate(),
    );
  }

  /// Create a copy of Ingredient with modified fields
  Ingredient copyWith({
    String? ingredientId,
    String? name,
    String? category,
    String? imageUrl,
    String? description,
    IngredientNutritionalInfo? nutritionalInfo,
    PurchaseInfo? purchaseInfo,
    List<String>? tags,
    List<String>? commonAllergens,
    List<String>? substitutes,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Ingredient(
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      purchaseInfo: purchaseInfo ?? this.purchaseInfo,
      tags: tags ?? this.tags,
      commonAllergens: commonAllergens ?? this.commonAllergens,
      substitutes: substitutes ?? this.substitutes,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Nutritional information for an ingredient (per standard serving)
class IngredientNutritionalInfo {
  final int calories;
  final double protein; // in grams
  final double carbs; // in grams
  final double fat; // in grams
  final double fiber; // in grams
  final Map<String, double> additionalNutrients; // e.g., vitamins, minerals
  final double standardServingSize; // in grams or ml
  final String standardServingUnit; // 'g', 'ml', 'cup', etc.

  IngredientNutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.additionalNutrients = const {},
    required this.standardServingSize,
    required this.standardServingUnit,
  });

  /// Convert IngredientNutritionalInfo object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'additionalNutrients': additionalNutrients,
      'standardServingSize': standardServingSize,
      'standardServingUnit': standardServingUnit,
    };
  }

  /// Create IngredientNutritionalInfo object from Firestore document
  factory IngredientNutritionalInfo.fromMap(Map<String, dynamic> map) {
    return IngredientNutritionalInfo(
      calories: map['calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num).toDouble(),
      additionalNutrients: Map<String, double>.from(
          map['additionalNutrients'] as Map? ?? {}),
      standardServingSize: (map['standardServingSize'] as num).toDouble(),
      standardServingUnit: map['standardServingUnit'] as String,
    );
  }
}

/// Purchase information for an ingredient
class PurchaseInfo {
  final String standardUnit; // e.g., kg, g, package, piece
  final double estimatedCostPerUnit; // in local currency
  final List<String> commonPurchaseForms; // e.g., fresh, frozen, canned
  final String? seasonalAvailability; // e.g., year-round, summer, winter
  final String? shelfLife; // e.g., '2 weeks in refrigerator'
  final String? storageRecommendation; // e.g., 'store in cool, dry place'

  PurchaseInfo({
    required this.standardUnit,
    this.estimatedCostPerUnit = 0.0,
    this.commonPurchaseForms = const [],
    this.seasonalAvailability,
    this.shelfLife,
    this.storageRecommendation,
  });

  /// Convert PurchaseInfo object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'standardUnit': standardUnit,
      'estimatedCostPerUnit': estimatedCostPerUnit,
      'commonPurchaseForms': commonPurchaseForms,
      'seasonalAvailability': seasonalAvailability,
      'shelfLife': shelfLife,
      'storageRecommendation': storageRecommendation,
    };
  }

  /// Create PurchaseInfo object from Firestore document
  factory PurchaseInfo.fromMap(Map<String, dynamic> map) {
    return PurchaseInfo(
      standardUnit: map['standardUnit'] as String,
      estimatedCostPerUnit:
          (map['estimatedCostPerUnit'] as num?)?.toDouble() ?? 0.0,
      commonPurchaseForms:
          List<String>.from(map['commonPurchaseForms'] as List? ?? []),
      seasonalAvailability: map['seasonalAvailability'] as String?,
      shelfLife: map['shelfLife'] as String?,
      storageRecommendation: map['storageRecommendation'] as String?,
    );
  }
} 