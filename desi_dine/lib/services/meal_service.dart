import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

/// Service for Meal model operations
class MealService {
  static final MealService _instance = MealService._internal();
  
  /// Access the singleton instance
  static MealService get instance => _instance;
  
  /// Firebase service reference
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Private constructor for singleton pattern
  MealService._internal();
  
  /// Create a new meal
  Future<Meal> createMeal(Meal meal) async {
    try {
      // Generate a document ID if not provided
      String mealId = meal.mealId.isEmpty ? _firebaseService.generateId(Constants.mealsCollection) : meal.mealId;
      
      // Create a new meal with the generated ID
      final mealWithId = Meal(
        mealId: mealId,
        name: meal.name,
        description: meal.description,
        imageUrl: meal.imageUrl,
        type: meal.type,
        cuisineType: meal.cuisineType,
        preparationTime: meal.preparationTime,
        cookingTime: meal.cookingTime,
        difficultyLevel: meal.difficultyLevel,
        nutritionalInfo: meal.nutritionalInfo,
        recipe: meal.recipe,
        tags: meal.tags,
        suitableHealthConditions: meal.suitableHealthConditions,
        seasonalRelevance: meal.seasonalRelevance,
        createdAt: meal.createdAt,
        lastModified: DateTime.now(),
      );
      
      // Save to Firestore
      await _firebaseService.setDocument(
        '${Constants.mealsCollection}/$mealId',
        mealWithId.toMap(),
      );
      
      return mealWithId;
    } catch (e) {
      throw FirebaseServiceException('Failed to create meal', e);
    }
  }
  
  /// Get a meal by ID
  Future<Meal?> getMealById(String mealId) async {
    try {
      final doc = await _firebaseService.getDocument('${Constants.mealsCollection}/$mealId');
      
      if (!doc.exists) {
        return null;
      }
      
      return Meal.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirebaseServiceException('Failed to get meal with ID: $mealId', e);
    }
  }
  
  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    try {
      // Create an updated meal with the current timestamp
      final updatedMeal = meal.copyWith(
        lastModified: DateTime.now(),
      );
      
      await _firebaseService.updateDocument(
        '${Constants.mealsCollection}/${meal.mealId}',
        updatedMeal.toMap(),
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to update meal with ID: ${meal.mealId}', e);
    }
  }
  
  /// Delete a meal by ID
  Future<void> deleteMeal(String mealId) async {
    try {
      await _firebaseService.deleteDocument('${Constants.mealsCollection}/$mealId');
    } catch (e) {
      throw FirebaseServiceException('Failed to delete meal with ID: $mealId', e);
    }
  }
  
  /// Get all meals
  Future<List<Meal>> getAllMeals() async {
    try {
      final querySnapshot = await _firebaseService.getCollection(Constants.mealsCollection);
      
      return querySnapshot.docs
          .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get all meals', e);
    }
  }
  
  /// Get meals by cuisine type
  Future<List<Meal>> getMealsByCuisine(String cuisineType) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('cuisineType', isEqualTo: cuisineType),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.mealsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get meals by cuisine: $cuisineType', e);
    }
  }
  
  /// Get meals by type (breakfast, lunch, dinner, snack)
  Future<List<Meal>> getMealsByType(String mealType) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('type', isEqualTo: mealType),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.mealsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get meals by type: $mealType', e);
    }
  }
  
  /// Get meals suitable for a health condition
  Future<List<Meal>> getMealsByHealthCondition(String healthCondition) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('suitableHealthConditions', arrayContains: healthCondition),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.mealsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get meals for health condition: $healthCondition', e);
    }
  }
  
  /// Get meals by tag
  Future<List<Meal>> getMealsByTag(String tag) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('tags', arrayContains: tag),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.mealsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get meals by tag: $tag', e);
    }
  }
  
  /// Stream a single meal by ID
  Stream<Meal?> streamMeal(String mealId) {
    try {
      return _firebaseService
          .streamDocument('${Constants.mealsCollection}/$mealId')
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return Meal.fromMap(snapshot.data() as Map<String, dynamic>);
          });
    } catch (e) {
      throw FirebaseServiceException('Failed to stream meal with ID: $mealId', e);
    }
  }
  
  /// Stream all meals for a particular meal type (breakfast, lunch, dinner)
  Stream<List<Meal>> streamMealsByType(String mealType) {
    try {
      final queryModifiers = [
        (Query query) => query.where('type', isEqualTo: mealType),
      ];
      
      return _firebaseService
          .streamCollection(Constants.mealsCollection, queryModifiers: queryModifiers)
          .map((snapshot) => snapshot.docs
              .map((doc) => Meal.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw FirebaseServiceException('Failed to stream meals by type: $mealType', e);
    }
  }
} 