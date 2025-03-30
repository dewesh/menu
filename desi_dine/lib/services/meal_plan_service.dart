import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'ai_service.dart' as ai;

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
      
      // For larger meal plans, generate in batches to avoid token limit issues
      if (numberOfDays > 3) {
        return await _generateMealPlanInBatches(
          userId: userId,
          cuisinePreferences: cuisinePreferences, 
          dietaryPreferences: dietaryPreferences,
          familySize: familySize,
          numberOfDays: numberOfDays,
          title: title,
          generationParameters: generationParameters,
          additionalPreferences: additionalPreferences,
        );
      }
      
      // For smaller meal plans, generate all at once
      final aiService = await ai.AIService.create();
      
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
  
  /// Generate a meal plan in batches to avoid token limit issues
  Future<MealPlan> _generateMealPlanInBatches({
    required String userId,
    required List<CuisinePreference> cuisinePreferences,
    required List<String> dietaryPreferences,
    required int familySize,
    required int numberOfDays,
    required Map<String, dynamic> generationParameters,
    String? title,
    Map<String, dynamic>? additionalPreferences,
  }) async {
    try {
      print('Generating meal plan in batches for $numberOfDays days');
      
      // Create the AI service
      final aiService = await ai.AIService.create();
      
      // Use a batch size of 2 days to ensure we stay within token limits
      const int batchSize = 2;
      final List<MealPlanDay> allDays = [];
      
      // Calculate number of batches needed
      final int numberOfBatches = (numberOfDays / batchSize).ceil();
      
      // Generate each batch
      for (int batchIndex = 0; batchIndex < numberOfBatches; batchIndex++) {
        // Calculate the number of days for this batch
        final int daysInThisBatch = (batchIndex == numberOfBatches - 1 && numberOfDays % batchSize != 0)
            ? numberOfDays % batchSize  // Last batch might be smaller
            : batchSize;
        
        print('Generating batch ${batchIndex + 1}/$numberOfBatches with $daysInThisBatch days');
        
        // Generate this batch of days
        final batchResponse = await aiService.generateMealPlan(
          cuisinePreferences: cuisinePreferences,
          dietaryPreferences: dietaryPreferences,
          familySize: familySize,
          numberOfDays: daysInThisBatch,
          additionalPreferences: additionalPreferences,
        );
        
        // Extract days from response
        final rawDays = (batchResponse['mealPlan']['days'] as List);
        final batchDays = rawDays
            .map((dayData) {
              // Adjust day number to be consecutive across batches
              final adjustedDayData = Map<String, dynamic>.from(dayData as Map<String, dynamic>);
              adjustedDayData['day'] = adjustedDayData['day'] + (batchIndex * batchSize);
              return MealPlanDay.fromAIResponse(adjustedDayData);
            })
            .toList();
            
        // Add days from this batch to the complete list
        allDays.addAll(batchDays);
      }
      
      // Sort days by day number
      allDays.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
      
      // Create the combined meal plan
      final now = DateTime.now();
      final mealPlanId = FirebaseFirestore.instance.collection('mealPlans').doc().id;
      
      final mealPlan = MealPlan(
        mealPlanId: mealPlanId,
        userId: userId,
        title: title ?? 'Meal Plan for $numberOfDays days',
        createdAt: now,
        lastModified: now,
        days: allDays,
        generationParameters: generationParameters,
      );
      
      // Save the meal plan to Firestore
      await saveMealPlan(mealPlan);
      
      return mealPlan;
    } catch (e) {
      print('Error generating meal plan in batches: $e');
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
      final aiService = await ai.AIService.create();
      
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
      
      // Generate just one day
      final aiResponse = await aiService.generateMealPlan(
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: 1, // Just one day
        additionalPreferences: params['additionalPreferences'],
      );
      
      // Extract the day from the response
      final dayData = (aiResponse['mealPlan']['days'] as List).first;
      
      // Since AI returned day 1, we need to adjust the day number to match the requested day
      final adjustedDayData = Map<String, dynamic>.from(dayData as Map<String, dynamic>);
      adjustedDayData['day'] = dayNumber;
      
      // Create a new day object
      final newDay = MealPlanDay.fromAIResponse(adjustedDayData);
      
      // Update the meal plan with the new day
      final updatedDays = List<MealPlanDay>.from(mealPlan.days);
      final dayIndex = updatedDays.indexWhere((day) => day.dayNumber == dayNumber);
      
      if (dayIndex >= 0) {
        updatedDays[dayIndex] = newDay;
      } else {
        updatedDays.add(newDay);
        updatedDays.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
      }
      
      // Create updated meal plan
      final updatedMealPlan = mealPlan.copyWith(
        days: updatedDays,
        lastModified: DateTime.now(),
      );
      
      // Save to Firestore
      await updateMealPlan(updatedMealPlan);
      
      return updatedMealPlan;
    } catch (e) {
      print('Error regenerating day: $e');
      rethrow;
    }
  }
  
  /// Regenerate a specific meal in a meal plan
  Future<MealPlan> regenerateMeal({
    required MealPlan mealPlan,
    required int dayNumber,
    required String mealType, // 'breakfast', 'lunch', 'dinner', or 'snack'
  }) async {
    try {
      // Create the AI service
      final aiService = await ai.AIService.create();
      
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
      
      // Additional parameters for the specific meal
      final additionalPrefs = Map<String, dynamic>.from(params['additionalPreferences'] ?? {});
      additionalPrefs['singleMeal'] = true;
      additionalPrefs['mealType'] = mealType;
      
      // Generate just one day with focus on the specific meal
      final aiResponse = await aiService.generateMealPlan(
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: 1, // Just one day
        additionalPreferences: additionalPrefs,
      );
      
      // Extract the day from the response
      final dayData = (aiResponse['mealPlan']['days'] as List).first;
      
      // Extract the specific meal from the AI response
      final newMealData = (dayData as Map<String, dynamic>)[mealType.toLowerCase()];
      
      // Convert to our model
      final newMeal = Meal.fromAIResponse(newMealData);
      
      // Update the meal plan with the new meal
      final updatedDays = List<MealPlanDay>.from(mealPlan.days);
      final dayIndex = updatedDays.indexWhere((day) => day.dayNumber == dayNumber);
      
      MealPlanDay updatedDay;
      
      if (dayIndex >= 0) {
        final day = updatedDays[dayIndex];
        
        // Create a new day with the regenerated meal
        if (mealType.toLowerCase() == 'breakfast') {
          updatedDay = MealPlanDay(
            dayNumber: day.dayNumber,
            breakfast: newMeal,
            lunch: day.lunch,
            dinner: day.dinner,
            snack: day.snack,
          );
        } else if (mealType.toLowerCase() == 'lunch') {
          updatedDay = MealPlanDay(
            dayNumber: day.dayNumber,
            breakfast: day.breakfast,
            lunch: newMeal,
            dinner: day.dinner,
            snack: day.snack,
          );
        } else if (mealType.toLowerCase() == 'dinner') {
          updatedDay = MealPlanDay(
            dayNumber: day.dayNumber,
            breakfast: day.breakfast,
            lunch: day.lunch,
            dinner: newMeal,
            snack: day.snack,
          );
        } else { // snack
          updatedDay = MealPlanDay(
            dayNumber: day.dayNumber,
            breakfast: day.breakfast,
            lunch: day.lunch,
            dinner: day.dinner,
            snack: newMeal,
          );
        }
        
        updatedDays[dayIndex] = updatedDay;
      }
      
      // Create updated meal plan
      final updatedMealPlan = mealPlan.copyWith(
        days: updatedDays,
        lastModified: DateTime.now(),
      );
      
      // Save to Firestore
      await updateMealPlan(updatedMealPlan);
      
      return updatedMealPlan;
    } catch (e) {
      print('Error regenerating meal: $e');
      rethrow;
    }
  }
} 