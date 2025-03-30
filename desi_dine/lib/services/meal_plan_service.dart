import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'ai_service.dart';

/// Service for meal plan operations including AI generation
class MealPlanService {
  static final MealPlanService _instance = MealPlanService._internal();
  
  /// Get the singleton instance
  static MealPlanService get instance => _instance;
  
  /// Firebase service reference
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Private constructor for singleton pattern
  MealPlanService._internal();
  
  /// Generate a meal plan using AI
  Future<MealPlan> generateMealPlan({
    required String userId,
    required List<CuisinePreference> cuisinePreferences,
    required List<String> dietaryPreferences,
    required int familySize,
    required int numberOfDays,
    String? title,
    Map<String, dynamic>? additionalPreferences,
  }) async {
    try {
      // Create the AI service
      final aiService = await AIService.create();
      
      // Prepare parameters
      final generationParameters = {
        'cuisinePreferences': cuisinePreferences.map((p) => {
          'cuisineType': p.cuisineType,
          'frequencyPreference': p.frequencyPreference,
        }).toList(),
        'dietaryPreferences': dietaryPreferences,
        'familySize': familySize,
        'numberOfDays': numberOfDays,
        'additionalPreferences': additionalPreferences,
      };
      
      // Generate the meal plan using AI
      final aiResponse = await aiService.generateMealPlan(
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: numberOfDays,
        additionalPreferences: additionalPreferences,
      );
      
      // Create a MealPlan object from the AI response
      final mealPlan = MealPlan.fromAIResponse(
        aiResponse,
        userId,
        title: title,
        generationParameters: generationParameters,
      );
      
      // Save the meal plan to Firestore
      await saveMealPlan(mealPlan);
      
      return mealPlan;
    } catch (e) {
      print('Error generating meal plan: $e');
      rethrow;
    }
  }
  
  /// Save a meal plan to Firestore
  Future<void> saveMealPlan(MealPlan mealPlan) async {
    try {
      await _firebaseService.setDocument(
        '${Constants.mealPlansCollection}/${mealPlan.mealPlanId}',
        mealPlan.toMap(),
      );
    } catch (e) {
      print('Error saving meal plan: $e');
      rethrow;
    }
  }
  
  /// Get a meal plan by ID
  Future<MealPlan?> getMealPlanById(String mealPlanId) async {
    try {
      final doc = await _firebaseService.getDocument(
        '${Constants.mealPlansCollection}/$mealPlanId',
      );
      
      if (!doc.exists) {
        return null;
      }
      
      return MealPlan.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting meal plan: $e');
      rethrow;
    }
  }
  
  /// Get all meal plans for a user
  Future<List<MealPlan>> getMealPlansForUser(String userId) async {
    try {
      final querySnapshot = await _firebaseService.getCollection(
        Constants.mealPlansCollection,
        queryModifiers: [
          (query) => query.where('userId', isEqualTo: userId),
          (query) => query.orderBy('createdAt', descending: true),
        ],
      );
      
      return querySnapshot.docs
          .map((doc) => MealPlan.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting meal plans for user: $e');
      rethrow;
    }
  }
  
  /// Update a meal plan
  Future<void> updateMealPlan(MealPlan mealPlan) async {
    try {
      // Update lastModified timestamp
      final updatedMealPlan = mealPlan.copyWith(
        lastModified: DateTime.now(),
      );
      
      await _firebaseService.updateDocument(
        '${Constants.mealPlansCollection}/${mealPlan.mealPlanId}',
        updatedMealPlan.toMap(),
      );
    } catch (e) {
      print('Error updating meal plan: $e');
      rethrow;
    }
  }
  
  /// Delete a meal plan
  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _firebaseService.deleteDocument(
        '${Constants.mealPlansCollection}/$mealPlanId',
      );
    } catch (e) {
      print('Error deleting meal plan: $e');
      rethrow;
    }
  }
  
  /// Toggle favorite status of a meal plan
  Future<MealPlan> toggleMealPlanFavorite(MealPlan mealPlan) async {
    try {
      final updatedMealPlan = mealPlan.copyWith(
        isFavorite: !mealPlan.isFavorite,
        lastModified: DateTime.now(),
      );
      
      await _firebaseService.updateDocument(
        '${Constants.mealPlansCollection}/${mealPlan.mealPlanId}',
        {
          'isFavorite': updatedMealPlan.isFavorite,
          'lastModified': Timestamp.fromDate(updatedMealPlan.lastModified),
        },
      );
      
      return updatedMealPlan;
    } catch (e) {
      print('Error toggling meal plan favorite status: $e');
      rethrow;
    }
  }
  
  /// Regenerate a specific day in a meal plan
  Future<MealPlan> regenerateDay({
    required MealPlan mealPlan,
    required int dayNumber,
  }) async {
    try {
      // Create the AI service
      final aiService = await AIService.create();
      
      // Extract parameters from the original meal plan
      final params = mealPlan.generationParameters;
      final cuisinePreferences = (params['cuisinePreferences'] as List)
          .map((p) => CuisinePreference(
                cuisineType: p['cuisineType'],
                frequencyPreference: p['frequencyPreference'],
              ))
          .toList();
      
      final dietaryPreferences = (params['dietaryPreferences'] as List)
          .map((p) => p.toString())
          .toList();
          
      final familySize = params['familySize'] as int;
      final additionalPreferences = params['additionalPreferences'] as Map<String, dynamic>?;
      
      // Generate a single day meal plan
      final aiResponse = await aiService.generateMealPlan(
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: 1, // Generate just one day
        additionalPreferences: additionalPreferences,
      );
      
      // Parse the response
      final dayData = (aiResponse['mealPlan']['days'] as List).first as Map<String, dynamic>;
      
      // Create a MealPlanDay with the correct day number
      final adjustedDayData = Map<String, dynamic>.from(dayData);
      adjustedDayData['day'] = dayNumber;
      
      final newDay = MealPlanDay.fromAIResponse(adjustedDayData);
      
      // Create updated days list
      final updatedDays = mealPlan.days.map((day) {
        return day.dayNumber == dayNumber ? newDay : day;
      }).toList();
      
      // Create updated meal plan
      final updatedMealPlan = mealPlan.copyWith(
        days: updatedDays,
        lastModified: DateTime.now(),
      );
      
      // Save to Firestore
      await saveMealPlan(updatedMealPlan);
      
      return updatedMealPlan;
    } catch (e) {
      print('Error regenerating day: $e');
      rethrow;
    }
  }
  
  /// Regenerate a specific meal in a day
  Future<MealPlan> regenerateMeal({
    required MealPlan mealPlan,
    required int dayNumber,
    required String mealType, // 'breakfast', 'lunch', 'dinner', 'snack'
  }) async {
    try {
      // TODO: Implement meal-specific regeneration
      // This would require a different endpoint or prompt structure
      // For now, regenerate the entire day and keep the non-targeted meals
      
      // Find the current day
      final currentDay = mealPlan.days.firstWhere(
        (day) => day.dayNumber == dayNumber,
      );
      
      // Create the AI service
      final aiService = await AIService.create();
      
      // Extract parameters from the original meal plan
      final params = mealPlan.generationParameters;
      final cuisinePreferences = (params['cuisinePreferences'] as List)
          .map((p) => CuisinePreference(
                cuisineType: p['cuisineType'],
                frequencyPreference: p['frequencyPreference'],
              ))
          .toList();
      
      final dietaryPreferences = (params['dietaryPreferences'] as List)
          .map((p) => p.toString())
          .toList();
          
      final familySize = params['familySize'] as int;
      final additionalPreferences = Map<String, dynamic>.from(params['additionalPreferences'] ?? {});
      
      // Add specific instructions for the targeted meal
      additionalPreferences['targetMeal'] = mealType;
      additionalPreferences['regenerateOnly'] = mealType;
      
      // Generate a single day meal plan with focus on the specific meal
      final aiResponse = await aiService.generateMealPlan(
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: 1, // Generate just one day
        additionalPreferences: additionalPreferences,
      );
      
      // Parse the response
      final dayData = (aiResponse['mealPlan']['days'] as List).first as Map<String, dynamic>;
      final newMealData = dayData[mealType] as Map<String, dynamic>;
      final newMeal = Meal.fromAIResponse(newMealData);
      
      // Create updated day with only the targeted meal replaced
      MealPlanDay updatedDay;
      switch (mealType) {
        case 'breakfast':
          updatedDay = MealPlanDay(
            dayNumber: dayNumber,
            breakfast: newMeal,
            lunch: currentDay.lunch,
            dinner: currentDay.dinner,
            snack: currentDay.snack,
          );
          break;
        case 'lunch':
          updatedDay = MealPlanDay(
            dayNumber: dayNumber,
            breakfast: currentDay.breakfast,
            lunch: newMeal,
            dinner: currentDay.dinner,
            snack: currentDay.snack,
          );
          break;
        case 'dinner':
          updatedDay = MealPlanDay(
            dayNumber: dayNumber,
            breakfast: currentDay.breakfast,
            lunch: currentDay.lunch,
            dinner: newMeal,
            snack: currentDay.snack,
          );
          break;
        case 'snack':
          updatedDay = MealPlanDay(
            dayNumber: dayNumber,
            breakfast: currentDay.breakfast,
            lunch: currentDay.lunch,
            dinner: currentDay.dinner,
            snack: newMeal,
          );
          break;
        default:
          throw Exception('Invalid meal type: $mealType');
      }
      
      // Create updated days list
      final updatedDays = mealPlan.days.map((day) {
        return day.dayNumber == dayNumber ? updatedDay : day;
      }).toList();
      
      // Create updated meal plan
      final updatedMealPlan = mealPlan.copyWith(
        days: updatedDays,
        lastModified: DateTime.now(),
      );
      
      // Save to Firestore
      await saveMealPlan(updatedMealPlan);
      
      return updatedMealPlan;
    } catch (e) {
      print('Error regenerating meal: $e');
      rethrow;
    }
  }
} 