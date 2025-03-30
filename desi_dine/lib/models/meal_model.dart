import 'package:cloud_firestore/cloud_firestore.dart';

/// Meal model representing a dish with recipe and nutritional information
class Meal {
  final String mealId;
  final String name;
  final String description;
  final String? imageUrl;
  final String type; // breakfast, lunch, dinner, snack
  final String cuisineType;
  final int preparationTime; // in minutes
  final int cookingTime; // in minutes
  final String difficultyLevel; // easy, medium, difficult
  final NutritionalInfo nutritionalInfo;
  final Recipe recipe;
  final List<String> tags;
  final List<String> suitableHealthConditions;
  final String seasonalRelevance; // year-round, summer, winter, etc.
  final DateTime createdAt;
  final DateTime lastModified;

  Meal({
    required this.mealId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.type,
    required this.cuisineType,
    required this.preparationTime,
    required this.cookingTime,
    required this.difficultyLevel,
    required this.nutritionalInfo,
    required this.recipe,
    this.tags = const [],
    this.suitableHealthConditions = const [],
    required this.seasonalRelevance,
    required this.createdAt,
    required this.lastModified,
  });

  /// Calculate total time (prep + cooking)
  int get totalTime => preparationTime + cookingTime;

  /// Convert Meal object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mealId': mealId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type,
      'cuisineType': cuisineType,
      'preparationTime': preparationTime,
      'cookingTime': cookingTime,
      'difficultyLevel': difficultyLevel,
      'nutritionalInfo': nutritionalInfo.toMap(),
      'recipe': recipe.toMap(),
      'tags': tags,
      'suitableHealthConditions': suitableHealthConditions,
      'seasonalRelevance': seasonalRelevance,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
    };
  }

  /// Create Meal object from Firestore document
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      mealId: map['mealId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String?,
      type: map['type'] as String,
      cuisineType: map['cuisineType'] as String,
      preparationTime: map['preparationTime'] as int,
      cookingTime: map['cookingTime'] as int,
      difficultyLevel: map['difficultyLevel'] as String,
      nutritionalInfo: NutritionalInfo.fromMap(map['nutritionalInfo']),
      recipe: Recipe.fromMap(map['recipe']),
      tags: List<String>.from(map['tags'] as List? ?? []),
      suitableHealthConditions:
          List<String>.from(map['suitableHealthConditions'] as List? ?? []),
      seasonalRelevance: map['seasonalRelevance'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: (map['lastModified'] as Timestamp).toDate(),
    );
  }

  /// Create a copy of Meal with modified fields
  Meal copyWith({
    String? mealId,
    String? name,
    String? description,
    String? imageUrl,
    String? type,
    String? cuisineType,
    int? preparationTime,
    int? cookingTime,
    String? difficultyLevel,
    NutritionalInfo? nutritionalInfo,
    Recipe? recipe,
    List<String>? tags,
    List<String>? suitableHealthConditions,
    String? seasonalRelevance,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Meal(
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      cuisineType: cuisineType ?? this.cuisineType,
      preparationTime: preparationTime ?? this.preparationTime,
      cookingTime: cookingTime ?? this.cookingTime,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      recipe: recipe ?? this.recipe,
      tags: tags ?? this.tags,
      suitableHealthConditions:
          suitableHealthConditions ?? this.suitableHealthConditions,
      seasonalRelevance: seasonalRelevance ?? this.seasonalRelevance,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Nutritional information for a meal
class NutritionalInfo {
  final int calories;
  final double protein; // in grams
  final double carbs; // in grams
  final double fat; // in grams
  final double fiber; // in grams
  final Map<String, double> additionalNutrients; // e.g., vitamins, minerals

  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    this.additionalNutrients = const {},
  });

  /// Convert NutritionalInfo object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'additionalNutrients': additionalNutrients,
    };
  }

  /// Create NutritionalInfo object from Firestore document
  factory NutritionalInfo.fromMap(Map<String, dynamic> map) {
    return NutritionalInfo(
      calories: map['calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      fiber: (map['fiber'] as num).toDouble(),
      additionalNutrients: Map<String, double>.from(
          map['additionalNutrients'] as Map? ?? {}),
    );
  }
}

/// Recipe details including ingredients and preparation steps
class Recipe {
  final List<RecipeIngredient> ingredients;
  final List<PreparationStep> preparationSteps;
  final int servingSize;
  final String? notes;

  Recipe({
    required this.ingredients,
    required this.preparationSteps,
    required this.servingSize,
    this.notes,
  });

  /// Convert Recipe object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'ingredients': ingredients.map((x) => x.toMap()).toList(),
      'preparationSteps': preparationSteps.map((x) => x.toMap()).toList(),
      'servingSize': servingSize,
      'notes': notes,
    };
  }

  /// Create Recipe object from Firestore document
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      ingredients: List<RecipeIngredient>.from(
        (map['ingredients'] as List).map(
          (x) => RecipeIngredient.fromMap(x),
        ),
      ),
      preparationSteps: List<PreparationStep>.from(
        (map['preparationSteps'] as List).map(
          (x) => PreparationStep.fromMap(x),
        ),
      ),
      servingSize: map['servingSize'] as int,
      notes: map['notes'] as String?,
    );
  }
}

/// Ingredient in a recipe with quantity and unit
class RecipeIngredient {
  final String ingredientId;
  final String name;
  final double quantity;
  final String unit; // grams, teaspoons, pieces, etc.
  final String? notes;
  final bool isOptional;

  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
    this.isOptional = false,
  });

  /// Convert RecipeIngredient object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'isOptional': isOptional,
    };
  }

  /// Create RecipeIngredient object from Firestore document
  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      ingredientId: map['ingredientId'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      notes: map['notes'] as String?,
      isOptional: map['isOptional'] as bool? ?? false,
    );
  }
}

/// Step in the preparation process of a recipe
class PreparationStep {
  final int stepNumber;
  final String description;
  final String? imageUrl;
  final int? timeTakenMinutes;

  PreparationStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
    this.timeTakenMinutes,
  });

  /// Convert PreparationStep object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'description': description,
      'imageUrl': imageUrl,
      'timeTakenMinutes': timeTakenMinutes,
    };
  }

  /// Create PreparationStep object from Firestore document
  factory PreparationStep.fromMap(Map<String, dynamic> map) {
    return PreparationStep(
      stepNumber: map['stepNumber'] as int,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String?,
      timeTakenMinutes: map['timeTakenMinutes'] as int?,
    );
  }
} 