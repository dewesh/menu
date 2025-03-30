import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_plan_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'ai_service.dart' as ai;
import 'user_service.dart';

/// Service for meal plan operations including AI generation
class MealPlanService {
  static final MealPlanService _instance = MealPlanService._internal();
  
  /// Get the singleton instance
  static MealPlanService get instance => _instance;
  
  /// Firebase service reference
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Private constructor for singleton pattern
  MealPlanService._internal();
  
  /// Get the active meal plan for a user, creating one if it doesn't exist
  Future<MealPlan> getOrCreateMealPlan({
    required String userId,
    List<CuisinePreference>? cuisinePreferences,
    List<String>? dietaryPreferences,
    int? familySize,
  }) async {
    try {
      // Try to fetch the user's existing meal plan
      final existingPlan = await _getUserMealPlan(userId);
      
      // If a meal plan exists and no preference updates are needed, return it
      if (existingPlan != null && 
          cuisinePreferences == null && 
          dietaryPreferences == null && 
          familySize == null) {
        return existingPlan;
      }
      
      // If we have a plan but need to update with new preferences
      if (existingPlan != null) {
        // Get current parameters from the existing plan
        final params = existingPlan.generationParameters;
        
        // Update with new values if provided
        if (cuisinePreferences != null) {
          params['cuisinePreferences'] = cuisinePreferences.map((p) => {
            'cuisineType': p.cuisineType,
            'frequencyPreference': p.frequencyPreference,
          }).toList();
        }
        
        if (dietaryPreferences != null) {
          params['dietaryPreferences'] = dietaryPreferences;
        }
        
        if (familySize != null) {
          params['familySize'] = familySize;
        }
        
        // Generate a new meal plan with updated preferences
        return await regenerateMealPlan(
          existingMealPlan: existingPlan,
          generationParameters: params,
        );
      }
      
      // No existing plan, fetch user preferences and create a new plan
      if (cuisinePreferences == null || dietaryPreferences == null || familySize == null) {
        final user = await UserService.instance.getUserById(userId);
        if (user == null) {
          throw Exception('User not found. Cannot generate meal plan.');
        }
        
        cuisinePreferences = cuisinePreferences ?? user.systemPreferences?.cuisinePreferences ?? [];
        dietaryPreferences = dietaryPreferences ?? user.systemPreferences?.dietaryPreferences ?? [];
        familySize = familySize ?? user.systemPreferences?.familySize ?? 1;
      }
      
      // Default to 7 days for a new meal plan
      const numberOfDays = 7;
      
      // Generate a new meal plan
      return await generateMealPlan(
        userId: userId,
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: numberOfDays,
      );
    } catch (e) {
      print('Error getting or creating meal plan: $e');
      rethrow;
    }
  }
  
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
      
      // Check if user already has a meal plan and delete it
      await _deleteExistingMealPlans(userId);
      
      // Save the new meal plan to Firestore
      await saveMealPlan(mealPlan);
      
      return mealPlan;
    } catch (e) {
      print('Error generating meal plan: $e');
      rethrow;
    }
  }
  
  /// Delete any existing meal plans for a user
  Future<void> _deleteExistingMealPlans(String userId) async {
    try {
      final existingPlans = await _firebaseService.getCollection(
        Constants.mealPlansCollection,
        queryModifiers: [
          (query) => query.where('userId', isEqualTo: userId),
        ],
      );
      
      for (final doc in existingPlans.docs) {
        await _firebaseService.deleteDocument('${Constants.mealPlansCollection}/${doc.id}');
      }
    } catch (e) {
      print('Error deleting existing meal plans: $e');
      // Continue even if deletion fails
    }
  }
  
  /// Regenerate an existing meal plan with new parameters
  Future<MealPlan> regenerateMealPlan({
    required MealPlan existingMealPlan,
    required Map<String, dynamic> generationParameters,
  }) async {
    try {
      // Extract parameters for generation
      final cuisinePreferences = (generationParameters['cuisinePreferences'] as List)
          .map((p) => CuisinePreference(
                cuisineType: p['cuisineType'],
                frequencyPreference: p['frequencyPreference'],
              ))
          .toList();
      
      final dietaryPreferences = (generationParameters['dietaryPreferences'] as List)
          .map((p) => p.toString())
          .toList();
          
      final familySize = generationParameters['familySize'] as int;
      final numberOfDays = existingMealPlan.days.length;
      
      // Generate a new meal plan
      return await generateMealPlan(
        userId: existingMealPlan.userId,
        cuisinePreferences: cuisinePreferences,
        dietaryPreferences: dietaryPreferences,
        familySize: familySize,
        numberOfDays: numberOfDays,
        additionalPreferences: generationParameters['additionalPreferences'],
      );
    } catch (e) {
      print('Error regenerating meal plan: $e');
      rethrow;
    }
  }

  /// Get the current meal plan for a user
  Future<MealPlan?> _getUserMealPlan(String userId) async {
    try {
      final querySnapshot = await _firebaseService.getCollection(
        Constants.mealPlansCollection,
        queryModifiers: [
          (query) => query.where('userId', isEqualTo: userId),
          (query) => query.orderBy('createdAt', descending: true),
          (query) => query.limit(1),
        ],
      );
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      try {
        return MealPlan.fromMap(querySnapshot.docs.first.data() as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing meal plan from database: $e');
        
        // Handle error by deleting corrupted document and returning null
        print('Deleting corrupted meal plan document: ${querySnapshot.docs.first.id}');
        await _firebaseService.deleteDocument(
          '${Constants.mealPlansCollection}/${querySnapshot.docs.first.id}'
        );
        
        return null;
      }
    } catch (e) {
      print('Error getting user meal plan: $e');
      
      // If there's an index error, we want to propagate it up
      if (e.toString().contains('FAILED_PRECONDITION') && 
          e.toString().contains('requires an index')) {
        rethrow;
      }
      
      // For other errors, we'll just return null to trigger new plan creation
      return null;
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
      final Map<DateTime, MealPlanDay> allDays = {};
      
      // Calculate number of batches needed
      final int numberOfBatches = (numberOfDays / batchSize).ceil();
      
      // Get the start date (today with time set to midnight)
      final startDate = DateTime.now().subtract(Duration(
        hours: DateTime.now().hour, 
        minutes: DateTime.now().minute, 
        seconds: DateTime.now().second,
        milliseconds: DateTime.now().millisecond,
      ));
      
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
        
        // Process each day in this batch
        for (int i = 0; i < rawDays.length; i++) {
          try {
            final dayData = rawDays[i] as Map<String, dynamic>;
            
            // Calculate the absolute day number and date
            final dayOffset = (batchIndex * batchSize) + i;
            final date = startDate.add(Duration(days: dayOffset));
            
            // Adjust day number to be consecutive across batches
            final adjustedDayData = Map<String, dynamic>.from(dayData);
            adjustedDayData['day'] = dayOffset + 1; // 1-indexed day number
            
            // Create the MealPlanDay and add to map
            allDays[date] = MealPlanDay.fromAIResponse(adjustedDayData, date);
          } catch (e) {
            print('Error processing day in batch: $e');
            // Continue with other days
          }
        }
      }
      
      if (allDays.isEmpty) {
        throw Exception('Failed to generate any valid days for the meal plan');
      }
      
      // Create the combined meal plan
      final now = DateTime.now();
      final mealPlanId = FirebaseFirestore.instance.collection('mealPlans').doc().id;
      
      final mealPlan = MealPlan(
        mealPlanId: mealPlanId,
        userId: userId,
        title: title ?? 'Meal Plan starting ${startDate.toIso8601String().substring(0, 10)}',
        createdAt: now,
        lastModified: now,
        days: allDays,
        generationParameters: generationParameters,
      );
      
      // Check if user already has a meal plan and delete it
      await _deleteExistingMealPlans(userId);
      
      // Save the new meal plan to Firestore
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
    required DateTime date,
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
      
      // Get the day number from the existing day or default to 1
      int dayNumber = 1;
      if (mealPlan.days.containsKey(date)) {
        dayNumber = mealPlan.days[date]!.dayNumber;
      } else {
        // Calculate day number based on difference from first day
        final firstDate = mealPlan.days.keys.reduce((a, b) => a.isBefore(b) ? a : b);
        dayNumber = date.difference(firstDate).inDays + 1;
      }
      
      // Adjust day number in response
      final adjustedDayData = Map<String, dynamic>.from(dayData as Map<String, dynamic>);
      adjustedDayData['day'] = dayNumber;
      
      // Create a new day object
      final newDay = MealPlanDay.fromAIResponse(adjustedDayData, date);
      
      // Update the meal plan with the new day
      final updatedDays = Map<DateTime, MealPlanDay>.from(mealPlan.days);
      updatedDays[date] = newDay;
      
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
    required DateTime date,
    required String mealType, // 'breakfast', 'lunch', 'dinner', or 'snack'
  }) async {
    try {
      // Check if the date exists in the meal plan
      if (!mealPlan.days.containsKey(date)) {
        throw Exception('Date $date not found in meal plan');
      }
      
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
      
      // Get the existing day
      final existingDay = mealPlan.days[date]!;
      
      // Create a new day with the regenerated meal
      MealPlanDay updatedDay;
      if (mealType.toLowerCase() == 'breakfast') {
        updatedDay = MealPlanDay(
          date: date,
          dayNumber: existingDay.dayNumber,
          breakfast: newMeal,
          lunch: existingDay.lunch,
          dinner: existingDay.dinner,
          snack: existingDay.snack,
        );
      } else if (mealType.toLowerCase() == 'lunch') {
        updatedDay = MealPlanDay(
          date: date,
          dayNumber: existingDay.dayNumber,
          breakfast: existingDay.breakfast,
          lunch: newMeal,
          dinner: existingDay.dinner,
          snack: existingDay.snack,
        );
      } else if (mealType.toLowerCase() == 'dinner') {
        updatedDay = MealPlanDay(
          date: date,
          dayNumber: existingDay.dayNumber,
          breakfast: existingDay.breakfast,
          lunch: existingDay.lunch,
          dinner: newMeal,
          snack: existingDay.snack,
        );
      } else { // snack
        updatedDay = MealPlanDay(
          date: date,
          dayNumber: existingDay.dayNumber,
          breakfast: existingDay.breakfast,
          lunch: existingDay.lunch,
          dinner: existingDay.dinner,
          snack: newMeal,
        );
      }
      
      // Update the meal plan with the new day
      final updatedDays = Map<DateTime, MealPlanDay>.from(mealPlan.days);
      updatedDays[date] = updatedDay;
      
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