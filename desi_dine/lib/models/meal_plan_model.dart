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
    final now = DateTime.now();
    final mealPlanId = FirebaseFirestore.instance.collection('mealPlans').doc().id;

    final rawDays = (responseJson['mealPlan']['days'] as List);
    final days = rawDays
        .map((dayData) => MealPlanDay.fromAIResponse(dayData as Map<String, dynamic>))
        .toList();

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
    return MealPlanDay(
      dayNumber: dayData['day'] as int,
      breakfast: Meal.fromAIResponse(dayData['breakfast'] as Map<String, dynamic>),
      lunch: Meal.fromAIResponse(dayData['lunch'] as Map<String, dynamic>),
      dinner: Meal.fromAIResponse(dayData['dinner'] as Map<String, dynamic>),
      snack: Meal.fromAIResponse(dayData['snack'] as Map<String, dynamic>),
    );
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
    final List<MealIngredient> ingredients = [];
    
    // Handle possible variations in the AI response format
    if (mealData['ingredients'] is List) {
      ingredients.addAll(
        (mealData['ingredients'] as List)
            .map((ingredient) => 
                MealIngredient.fromAIResponse(ingredient as Map<String, dynamic>)
            )
            .toList(),
      );
    }
    
    return Meal(
      name: mealData['name'] as String,
      cuisineType: mealData['cuisineType'] as String?,
      ingredients: ingredients,
      instructions: mealData['instructions'] as String,
      nutritionalInfo: NutritionalInfo.fromAIResponse(mealData['nutritionalInfo'] as Map<String, dynamic>),
    );
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
      protein: (map['protein'] is int) 
          ? (map['protein'] as int).toDouble() 
          : map['protein'] as double,
      carbs: (map['carbs'] is int) 
          ? (map['carbs'] as int).toDouble() 
          : map['carbs'] as double,
      fat: (map['fat'] is int) 
          ? (map['fat'] as int).toDouble() 
          : map['fat'] as double,
    );
  }

  /// Create NutritionalInfo from the AI generated JSON
  factory NutritionalInfo.fromAIResponse(Map<String, dynamic> nutritionData) {
    // Handle possible variations in the AI response format
    final calories = nutritionData['calories'] is String
        ? int.tryParse(nutritionData['calories'] as String) ?? 0
        : nutritionData['calories'] as int? ?? 0;
        
    final protein = _parseDoubleValue(nutritionData['protein']);
    final carbs = _parseDoubleValue(nutritionData['carbs']);
    final fat = _parseDoubleValue(nutritionData['fat']);
    
    return NutritionalInfo(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
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