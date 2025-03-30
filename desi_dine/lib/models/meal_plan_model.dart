import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient_model.dart';

/// A complete meal plan generated by AI
class MealPlan {
  final String mealPlanId;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<MealPlanDay> days;
  final Map<String, dynamic> generationParameters;
  final bool isFavorite;

  MealPlan({
    required this.mealPlanId,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    required this.days,
    required this.generationParameters,
    this.isFavorite = false,
  });

  /// Convert MealPlan to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mealPlanId': mealPlanId,
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
      'days': days.map((day) => day.toMap()).toList(),
      'generationParameters': generationParameters,
      'isFavorite': isFavorite,
    };
  }

  /// Create MealPlan from a map (Firestore document)
  factory MealPlan.fromMap(Map<String, dynamic> map) {
    return MealPlan(
      mealPlanId: map['mealPlanId'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: (map['lastModified'] as Timestamp).toDate(),
      days: (map['days'] as List)
          .map((dayMap) => MealPlanDay.fromMap(dayMap as Map<String, dynamic>))
          .toList(),
      generationParameters: Map<String, dynamic>.from(map['generationParameters'] as Map),
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  /// Create MealPlan from the AI generated JSON
  factory MealPlan.fromAIResponse(
    Map<String, dynamic> responseJson,
    String userId, {
    String? title,
    required Map<String, dynamic> generationParameters,
  }) {
    try {
      final now = DateTime.now();
      final mealPlanId = FirebaseFirestore.instance.collection('mealPlans').doc().id;

      // Validate the response structure
      if (!responseJson.containsKey('mealPlan') || 
          !(responseJson['mealPlan'] is Map) || 
          !responseJson['mealPlan'].containsKey('days') ||
          !(responseJson['mealPlan']['days'] is List)) {
        throw FormatException('Invalid meal plan response structure: ${responseJson.keys}');
      }

      final rawDays = (responseJson['mealPlan']['days'] as List);
      if (rawDays.isEmpty) {
        throw FormatException('Meal plan contains no days');
      }
      
      final days = <MealPlanDay>[];
      
      // Process each day with error handling
      for (var dayData in rawDays) {
        try {
          if (dayData is Map<String, dynamic>) {
            days.add(MealPlanDay.fromAIResponse(dayData));
          } else {
            print('Warning: Skipping invalid day data: $dayData');
          }
        } catch (e) {
          print('Error processing day data: $e');
          // Continue with other days instead of failing completely
        }
      }
      
      if (days.isEmpty) {
        throw FormatException('Failed to process any valid days from the meal plan');
      }

      // Sort days by day number if needed
      days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

      return MealPlan(
        mealPlanId: mealPlanId,
        userId: userId,
        title: title ?? 'Meal Plan for ${days.length} days',
        createdAt: now,
        lastModified: now,
        days: days,
        generationParameters: generationParameters,
      );
    } catch (e) {
      print('Error creating meal plan from AI response: $e');
      rethrow;
    }
  }

  /// Create a copy of MealPlan with modified fields
  MealPlan copyWith({
    String? mealPlanId,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? lastModified,
    List<MealPlanDay>? days,
    Map<String, dynamic>? generationParameters,
    bool? isFavorite,
  }) {
    return MealPlan(
      mealPlanId: mealPlanId ?? this.mealPlanId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      days: days ?? this.days,
      generationParameters: generationParameters ?? this.generationParameters,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// A single day in a meal plan
class MealPlanDay {
  final int dayNumber;
  final Meal breakfast;
  final Meal lunch;
  final Meal dinner;
  final Meal snack;

  MealPlanDay({
    required this.dayNumber,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  /// Convert MealPlanDay to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'breakfast': breakfast.toMap(),
      'lunch': lunch.toMap(),
      'dinner': dinner.toMap(),
      'snack': snack.toMap(),
    };
  }

  /// Create MealPlanDay from a map (Firestore document)
  factory MealPlanDay.fromMap(Map<String, dynamic> map) {
    return MealPlanDay(
      dayNumber: map['dayNumber'] as int,
      breakfast: Meal.fromMap(map['breakfast'] as Map<String, dynamic>),
      lunch: Meal.fromMap(map['lunch'] as Map<String, dynamic>),
      dinner: Meal.fromMap(map['dinner'] as Map<String, dynamic>),
      snack: Meal.fromMap(map['snack'] as Map<String, dynamic>),
    );
  }

  /// Create MealPlanDay from the AI generated JSON
  factory MealPlanDay.fromAIResponse(Map<String, dynamic> dayData) {
    try {
      // Validate day number exists
      final dayNumber = dayData.containsKey('day') ? dayData['day'] as int : 1;
      
      // Create a placeholder for missing or invalid meals
      final placeholderMeal = Meal(
        name: "Meal data unavailable",
        cuisineType: "Not specified",
        ingredients: [],
        instructions: "No instructions available. This meal could not be properly generated.",
        nutritionalInfo: NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      );
      
      // Parse each meal with error handling
      Meal breakfast = placeholderMeal;
      Meal lunch = placeholderMeal;
      Meal dinner = placeholderMeal;
      Meal snack = placeholderMeal;
      
      try {
        if (dayData.containsKey('breakfast') && dayData['breakfast'] is Map<String, dynamic>) {
          breakfast = Meal.fromAIResponse(dayData['breakfast'] as Map<String, dynamic>);
        } else {
          print('Warning: Invalid breakfast data for day $dayNumber');
        }
      } catch (e) {
        print('Error parsing breakfast for day $dayNumber: $e');
      }
      
      try {
        if (dayData.containsKey('lunch') && dayData['lunch'] is Map<String, dynamic>) {
          lunch = Meal.fromAIResponse(dayData['lunch'] as Map<String, dynamic>);
        } else {
          print('Warning: Invalid lunch data for day $dayNumber');
        }
      } catch (e) {
        print('Error parsing lunch for day $dayNumber: $e');
      }
      
      try {
        if (dayData.containsKey('dinner') && dayData['dinner'] is Map<String, dynamic>) {
          dinner = Meal.fromAIResponse(dayData['dinner'] as Map<String, dynamic>);
        } else {
          print('Warning: Invalid dinner data for day $dayNumber');
        }
      } catch (e) {
        print('Error parsing dinner for day $dayNumber: $e');
      }
      
      try {
        if (dayData.containsKey('snack') && dayData['snack'] is Map<String, dynamic>) {
          snack = Meal.fromAIResponse(dayData['snack'] as Map<String, dynamic>);
        } else {
          print('Warning: Invalid snack data for day $dayNumber');
        }
      } catch (e) {
        print('Error parsing snack for day $dayNumber: $e');
      }
      
      return MealPlanDay(
        dayNumber: dayNumber,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snack: snack,
      );
    } catch (e) {
      print('Error creating MealPlanDay from AI response: $e');
      rethrow;
    }
  }
}

/// A single meal in a meal plan day
class Meal {
  final String name;
  final String? cuisineType;
  final List<MealIngredient> ingredients;
  final String instructions;
  final NutritionalInfo nutritionalInfo;
  final bool isFavorite;

  Meal({
    required this.name,
    this.cuisineType,
    required this.ingredients,
    required this.instructions,
    required this.nutritionalInfo,
    this.isFavorite = false,
  });

  /// Convert Meal to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cuisineType': cuisineType,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'instructions': instructions,
      'nutritionalInfo': nutritionalInfo.toMap(),
      'isFavorite': isFavorite,
    };
  }

  /// Create Meal from a map (Firestore document)
  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      name: map['name'] as String,
      cuisineType: map['cuisineType'] as String?,
      ingredients: (map['ingredients'] as List)
          .map((ingredientMap) => MealIngredient.fromMap(ingredientMap as Map<String, dynamic>))
          .toList(),
      instructions: map['instructions'] as String,
      nutritionalInfo: NutritionalInfo.fromMap(map['nutritionalInfo'] as Map<String, dynamic>),
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  /// Create Meal from the AI generated JSON
  factory Meal.fromAIResponse(Map<String, dynamic> mealData) {
    try {
      // Get name or use placeholder
      final name = mealData.containsKey('name') && mealData['name'] is String
          ? mealData['name'] as String
          : "Unnamed Meal";
          
      // Get cuisine type safely
      final cuisineType = mealData.containsKey('cuisineType') && mealData['cuisineType'] is String
          ? mealData['cuisineType'] as String
          : "Not specified";
      
      // Parse ingredients with error handling
      final List<MealIngredient> ingredients = [];
      if (mealData.containsKey('ingredients') && mealData['ingredients'] is List) {
        for (var ingredientData in mealData['ingredients'] as List) {
          try {
            if (ingredientData is Map<String, dynamic>) {
              ingredients.add(MealIngredient.fromAIResponse(ingredientData));
            }
          } catch (e) {
            print('Error parsing ingredient: $e');
            // Continue with other ingredients
          }
        }
      }
      
      // Get instructions safely
      final instructions = mealData.containsKey('instructions') && mealData['instructions'] is String
          ? mealData['instructions'] as String
          : "No instructions available";
      
      // Parse nutritional info with fallback
      NutritionalInfo nutritionalInfo;
      try {
        if (mealData.containsKey('nutritionalInfo') && mealData['nutritionalInfo'] is Map<String, dynamic>) {
          nutritionalInfo = NutritionalInfo.fromAIResponse(mealData['nutritionalInfo'] as Map<String, dynamic>);
        } else {
          nutritionalInfo = NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
        }
      } catch (e) {
        print('Error parsing nutritional info: $e');
        nutritionalInfo = NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0);
      }
      
      return Meal(
        name: name,
        cuisineType: cuisineType,
        ingredients: ingredients,
        instructions: instructions,
        nutritionalInfo: nutritionalInfo,
      );
    } catch (e) {
      print('Error creating Meal from AI response: $e');
      // Return a minimal valid meal rather than failing
      return Meal(
        name: "Error parsing meal",
        cuisineType: "Unknown",
        ingredients: [],
        instructions: "An error occurred while processing this meal.",
        nutritionalInfo: NutritionalInfo(calories: 0, protein: 0, carbs: 0, fat: 0),
      );
    }
  }

  /// Create a copy of Meal with modified fields
  Meal copyWith({
    String? name,
    String? cuisineType,
    List<MealIngredient>? ingredients,
    String? instructions,
    NutritionalInfo? nutritionalInfo,
    bool? isFavorite,
  }) {
    return Meal(
      name: name ?? this.name,
      cuisineType: cuisineType ?? this.cuisineType,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// An ingredient for a meal in a meal plan
class MealIngredient {
  final String name;
  final String quantity;
  final String? unit;

  MealIngredient({
    required this.name,
    required this.quantity,
    this.unit,
  });

  /// Convert MealIngredient to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  /// Create MealIngredient from a map (Firestore document)
  factory MealIngredient.fromMap(Map<String, dynamic> map) {
    return MealIngredient(
      name: map['name'] as String,
      quantity: map['quantity'] as String,
      unit: map['unit'] as String?,
    );
  }

  /// Create MealIngredient from the AI generated JSON
  factory MealIngredient.fromAIResponse(Map<String, dynamic> ingredientData) {
    return MealIngredient(
      name: ingredientData['name'] as String,
      quantity: ingredientData['quantity'] as String,
      unit: ingredientData['unit'] as String?,
    );
  }
}

/// Nutritional information for a meal
class NutritionalInfo {
  final int calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams

  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Convert NutritionalInfo to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  /// Create NutritionalInfo from a map (Firestore document)
  factory NutritionalInfo.fromMap(Map<String, dynamic> map) {
    return NutritionalInfo(
      calories: map['calories'] as int,
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
    );
  }

  /// Create NutritionalInfo from AI response with error handling
  factory NutritionalInfo.fromAIResponse(Map<String, dynamic> nutritionData) {
    try {
      // Convert numeric values safely
      int getIntValue(String key, int defaultValue) {
        if (!nutritionData.containsKey(key)) return defaultValue;
        final value = nutritionData[key];
        if (value is int) return value;
        if (value is double) return value.round();
        if (value is String) return int.tryParse(value) ?? defaultValue;
        return defaultValue;
      }
      
      double getDoubleValue(String key, double defaultValue) {
        if (!nutritionData.containsKey(key)) return defaultValue;
        final value = nutritionData[key];
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? defaultValue;
        return defaultValue;
      }

      return NutritionalInfo(
        calories: getIntValue('calories', 0),
        protein: getDoubleValue('protein', 0),
        carbs: getDoubleValue('carbs', 0),
        fat: getDoubleValue('fat', 0),
      );
    } catch (e) {
      print('Error parsing nutritional info: $e');
      return NutritionalInfo(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
    }
  }
}

/// Helper function to parse numeric values from different formats in AI responses
double _parseDoubleValue(dynamic value) {
  if (value == null) return 0.0;
  
  if (value is double) return value;
  if (value is int) return value.toDouble();
  
  if (value is String) {
    // Handle strings like "10g" or "10 g"
    final numericPattern = RegExp(r'([0-9]+\.?[0-9]*)');
    final match = numericPattern.firstMatch(value);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
  }
  
  return 0.0;
} 