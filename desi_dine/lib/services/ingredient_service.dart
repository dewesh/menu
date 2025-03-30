import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ingredient_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

/// Service for Ingredient model operations
class IngredientService {
  static final IngredientService _instance = IngredientService._internal();
  
  /// Access the singleton instance
  static IngredientService get instance => _instance;
  
  /// Firebase service reference
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Private constructor for singleton pattern
  IngredientService._internal();
  
  /// Create a new ingredient
  Future<Ingredient> createIngredient(Ingredient ingredient) async {
    try {
      // Generate a document ID if not provided
      String ingredientId = ingredient.ingredientId.isEmpty ? 
          _firebaseService.generateId(Constants.ingredientsCollection) : 
          ingredient.ingredientId;
      
      // Create a new ingredient with the generated ID
      final ingredientWithId = Ingredient(
        ingredientId: ingredientId,
        name: ingredient.name,
        category: ingredient.category,
        imageUrl: ingredient.imageUrl,
        description: ingredient.description,
        nutritionalInfo: ingredient.nutritionalInfo,
        purchaseInfo: ingredient.purchaseInfo,
        tags: ingredient.tags,
        commonAllergens: ingredient.commonAllergens,
        substitutes: ingredient.substitutes,
        isVegetarian: ingredient.isVegetarian,
        isVegan: ingredient.isVegan,
        isGlutenFree: ingredient.isGlutenFree,
        createdAt: ingredient.createdAt,
        lastModified: DateTime.now(),
      );
      
      // Save to Firestore
      await _firebaseService.setDocument(
        '${Constants.ingredientsCollection}/$ingredientId',
        ingredientWithId.toMap(),
      );
      
      return ingredientWithId;
    } catch (e) {
      throw FirebaseServiceException('Failed to create ingredient', e);
    }
  }
  
  /// Get an ingredient by ID
  Future<Ingredient?> getIngredientById(String ingredientId) async {
    try {
      final doc = await _firebaseService.getDocument('${Constants.ingredientsCollection}/$ingredientId');
      
      if (!doc.exists) {
        return null;
      }
      
      return Ingredient.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirebaseServiceException('Failed to get ingredient with ID: $ingredientId', e);
    }
  }
  
  /// Update an existing ingredient
  Future<void> updateIngredient(Ingredient ingredient) async {
    try {
      // Create an updated ingredient with the current timestamp
      final updatedIngredient = ingredient.copyWith(
        lastModified: DateTime.now(),
      );
      
      await _firebaseService.updateDocument(
        '${Constants.ingredientsCollection}/${ingredient.ingredientId}',
        updatedIngredient.toMap(),
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to update ingredient with ID: ${ingredient.ingredientId}', e);
    }
  }
  
  /// Delete an ingredient by ID
  Future<void> deleteIngredient(String ingredientId) async {
    try {
      await _firebaseService.deleteDocument('${Constants.ingredientsCollection}/$ingredientId');
    } catch (e) {
      throw FirebaseServiceException('Failed to delete ingredient with ID: $ingredientId', e);
    }
  }
  
  /// Get all ingredients
  Future<List<Ingredient>> getAllIngredients() async {
    try {
      final querySnapshot = await _firebaseService.getCollection(Constants.ingredientsCollection);
      
      return querySnapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get all ingredients', e);
    }
  }
  
  /// Get ingredients by category (vegetable, spice, grain, etc.)
  Future<List<Ingredient>> getIngredientsByCategory(String category) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('category', isEqualTo: category),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.ingredientsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get ingredients by category: $category', e);
    }
  }
  
  /// Get ingredients by dietary restriction
  Future<List<Ingredient>> getIngredientsByDietaryRestriction({
    bool vegetarian = false, 
    bool vegan = false, 
    bool glutenFree = false
  }) async {
    try {
      List<Query Function(Query)> queryModifiers = [];
      
      if (vegetarian) {
        queryModifiers.add((Query query) => query.where('isVegetarian', isEqualTo: true));
      }
      
      if (vegan) {
        queryModifiers.add((Query query) => query.where('isVegan', isEqualTo: true));
      }
      
      if (glutenFree) {
        queryModifiers.add((Query query) => query.where('isGlutenFree', isEqualTo: true));
      }
      
      if (queryModifiers.isEmpty) {
        return getAllIngredients();
      }
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.ingredientsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get ingredients by dietary restriction', e);
    }
  }
  
  /// Get ingredients by tag
  Future<List<Ingredient>> getIngredientsByTag(String tag) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('tags', arrayContains: tag),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.ingredientsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get ingredients by tag: $tag', e);
    }
  }
  
  /// Search ingredients by name
  Future<List<Ingredient>> searchIngredientsByName(String query) async {
    try {
      // We need to implement Firebase text search using an index
      // For simplicity, we'll get all ingredients and filter client-side for now
      final querySnapshot = await _firebaseService.getCollection(Constants.ingredientsCollection);
      
      return querySnapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
          .where((ingredient) => 
              ingredient.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to search ingredients by name: $query', e);
    }
  }
  
  /// Stream a single ingredient by ID
  Stream<Ingredient?> streamIngredient(String ingredientId) {
    try {
      return _firebaseService
          .streamDocument('${Constants.ingredientsCollection}/$ingredientId')
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return Ingredient.fromMap(snapshot.data() as Map<String, dynamic>);
          });
    } catch (e) {
      throw FirebaseServiceException('Failed to stream ingredient with ID: $ingredientId', e);
    }
  }
  
  /// Stream all ingredients of a specific category
  Stream<List<Ingredient>> streamIngredientsByCategory(String category) {
    try {
      final queryModifiers = [
        (Query query) => query.where('category', isEqualTo: category),
      ];
      
      return _firebaseService
          .streamCollection(Constants.ingredientsCollection, queryModifiers: queryModifiers)
          .map((snapshot) => snapshot.docs
              .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw FirebaseServiceException('Failed to stream ingredients by category: $category', e);
    }
  }
} 