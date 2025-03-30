import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grocery_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

/// Service for Grocery model operations
class GroceryService {
  static final GroceryService _instance = GroceryService._internal();
  
  /// Access the singleton instance
  static GroceryService get instance => _instance;
  
  /// Firebase service reference
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Private constructor for singleton pattern
  GroceryService._internal();
  
  /// Create a new grocery list
  Future<GroceryList> createGroceryList(GroceryList groceryList) async {
    try {
      // Generate a document ID if not provided
      String groceryListId = groceryList.groceryListId.isEmpty ? 
          _firebaseService.generateId(Constants.groceryListsCollection) : 
          groceryList.groceryListId;
      
      // Create a new grocery list with the generated ID
      final groceryListWithId = GroceryList(
        groceryListId: groceryListId,
        userId: groceryList.userId,
        title: groceryList.title,
        mealPlanId: groceryList.mealPlanId,
        categories: groceryList.categories,
        createdAt: groceryList.createdAt,
        lastModified: DateTime.now(),
        isShared: groceryList.isShared,
      );
      
      // Save to Firestore
      await _firebaseService.setDocument(
        '${Constants.groceryListsCollection}/$groceryListId',
        groceryListWithId.toMap(),
      );
      
      return groceryListWithId;
    } catch (e) {
      throw FirebaseServiceException('Failed to create grocery list', e);
    }
  }
  
  /// Get a grocery list by ID
  Future<GroceryList?> getGroceryListById(String groceryListId) async {
    try {
      final doc = await _firebaseService.getDocument('${Constants.groceryListsCollection}/$groceryListId');
      
      if (!doc.exists) {
        return null;
      }
      
      return GroceryList.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirebaseServiceException('Failed to get grocery list with ID: $groceryListId', e);
    }
  }
  
  /// Update an existing grocery list
  Future<void> updateGroceryList(GroceryList groceryList) async {
    try {
      // Create an updated grocery list with the current timestamp
      final updatedGroceryList = GroceryList(
        groceryListId: groceryList.groceryListId,
        userId: groceryList.userId,
        title: groceryList.title,
        mealPlanId: groceryList.mealPlanId,
        categories: groceryList.categories,
        createdAt: groceryList.createdAt,
        lastModified: DateTime.now(),
        isShared: groceryList.isShared,
      );
      
      await _firebaseService.updateDocument(
        '${Constants.groceryListsCollection}/${groceryList.groceryListId}',
        updatedGroceryList.toMap(),
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to update grocery list with ID: ${groceryList.groceryListId}', e);
    }
  }
  
  /// Delete a grocery list by ID
  Future<void> deleteGroceryList(String groceryListId) async {
    try {
      await _firebaseService.deleteDocument('${Constants.groceryListsCollection}/$groceryListId');
    } catch (e) {
      throw FirebaseServiceException('Failed to delete grocery list with ID: $groceryListId', e);
    }
  }
  
  /// Get all grocery lists for a user
  Future<List<GroceryList>> getGroceryListsByUserId(String userId) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('userId', isEqualTo: userId),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.groceryListsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => GroceryList.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get grocery lists for user: $userId', e);
    }
  }
  
  /// Get grocery lists by meal plan ID
  Future<List<GroceryList>> getGroceryListsByMealPlan(String mealPlanId) async {
    try {
      final queryModifiers = [
        (Query query) => query.where('mealPlanId', isEqualTo: mealPlanId),
      ];
      
      final querySnapshot = await _firebaseService.getCollection(
        Constants.groceryListsCollection,
        queryModifiers: queryModifiers,
      );
      
      return querySnapshot.docs
          .map((doc) => GroceryList.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get grocery lists for meal plan: $mealPlanId', e);
    }
  }
  
  /// Update item status (mark as purchased/unpurchased)
  Future<void> updateItemStatus(
    String groceryListId, 
    String categoryId, 
    String itemId, 
    bool isPurchased
  ) async {
    try {
      // First, get the current grocery list
      final groceryListDoc = await _firebaseService.getDocument('${Constants.groceryListsCollection}/$groceryListId');
      
      if (!groceryListDoc.exists) {
        throw FirebaseServiceException('Grocery list not found: $groceryListId');
      }
      
      final groceryList = GroceryList.fromMap(groceryListDoc.data() as Map<String, dynamic>);
      
      // Find the category and item
      final categoryIndex = groceryList.categories.indexWhere((cat) => cat.categoryId == categoryId);
      if (categoryIndex == -1) {
        throw FirebaseServiceException('Category not found: $categoryId');
      }
      
      final category = groceryList.categories[categoryIndex];
      final itemIndex = category.items.indexWhere((item) => item.itemId == itemId);
      if (itemIndex == -1) {
        throw FirebaseServiceException('Item not found: $itemId');
      }
      
      // Update the item's purchase status
      final updatedItem = GroceryItem(
        itemId: itemId,
        name: category.items[itemIndex].name,
        quantity: category.items[itemIndex].quantity,
        unit: category.items[itemIndex].unit,
        notes: category.items[itemIndex].notes,
        ingredientId: category.items[itemIndex].ingredientId,
        isPurchased: isPurchased,
        priority: category.items[itemIndex].priority,
      );
      
      // Create a new categories list with the updated item
      final updatedItems = List<GroceryItem>.from(category.items);
      updatedItems[itemIndex] = updatedItem;
      
      final updatedCategory = GroceryCategory(
        categoryId: categoryId,
        name: category.name,
        items: updatedItems,
        order: category.order,
      );
      
      final updatedCategories = List<GroceryCategory>.from(groceryList.categories);
      updatedCategories[categoryIndex] = updatedCategory;
      
      // Update the grocery list with the modified categories
      await _firebaseService.updateDocument(
        '${Constants.groceryListsCollection}/$groceryListId',
        {
          'categories': updatedCategories.map((c) => c.toMap()).toList(),
          'lastModified': Timestamp.fromDate(DateTime.now()),
        },
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to update item status', e);
    }
  }
  
  /// Add item to a grocery list
  Future<void> addItemToGroceryList(
    String groceryListId,
    String categoryId,
    GroceryItem newItem
  ) async {
    try {
      // First, get the current grocery list
      final groceryListDoc = await _firebaseService.getDocument('${Constants.groceryListsCollection}/$groceryListId');
      
      if (!groceryListDoc.exists) {
        throw FirebaseServiceException('Grocery list not found: $groceryListId');
      }
      
      final groceryList = GroceryList.fromMap(groceryListDoc.data() as Map<String, dynamic>);
      
      // Find the category
      final categoryIndex = groceryList.categories.indexWhere((cat) => cat.categoryId == categoryId);
      
      if (categoryIndex == -1) {
        // Create the category if it doesn't exist
        final newCategory = GroceryCategory(
          categoryId: categoryId.isEmpty ? _firebaseService.generateId(Constants.groceryListsCollection) : categoryId,
          name: 'New Category', // Default name
          items: [newItem],
          order: groceryList.categories.length, // Add to the end
        );
        
        final updatedCategories = List<GroceryCategory>.from(groceryList.categories)..add(newCategory);
        
        await _firebaseService.updateDocument(
          '${Constants.groceryListsCollection}/$groceryListId',
          {
            'categories': updatedCategories.map((c) => c.toMap()).toList(),
            'lastModified': Timestamp.fromDate(DateTime.now()),
          },
        );
      } else {
        // Add item to existing category
        final category = groceryList.categories[categoryIndex];
        final updatedItems = List<GroceryItem>.from(category.items)..add(newItem);
        
        final updatedCategory = GroceryCategory(
          categoryId: categoryId,
          name: category.name,
          items: updatedItems,
          order: category.order,
        );
        
        final updatedCategories = List<GroceryCategory>.from(groceryList.categories);
        updatedCategories[categoryIndex] = updatedCategory;
        
        await _firebaseService.updateDocument(
          '${Constants.groceryListsCollection}/$groceryListId',
          {
            'categories': updatedCategories.map((c) => c.toMap()).toList(),
            'lastModified': Timestamp.fromDate(DateTime.now()),
          },
        );
      }
    } catch (e) {
      throw FirebaseServiceException('Failed to add item to grocery list', e);
    }
  }
  
  /// Remove item from a grocery list
  Future<void> removeItemFromGroceryList(
    String groceryListId,
    String categoryId,
    String itemId
  ) async {
    try {
      // First, get the current grocery list
      final groceryListDoc = await _firebaseService.getDocument('${Constants.groceryListsCollection}/$groceryListId');
      
      if (!groceryListDoc.exists) {
        throw FirebaseServiceException('Grocery list not found: $groceryListId');
      }
      
      final groceryList = GroceryList.fromMap(groceryListDoc.data() as Map<String, dynamic>);
      
      // Find the category
      final categoryIndex = groceryList.categories.indexWhere((cat) => cat.categoryId == categoryId);
      if (categoryIndex == -1) {
        throw FirebaseServiceException('Category not found: $categoryId');
      }
      
      final category = groceryList.categories[categoryIndex];
      
      // Remove the item
      final updatedItems = List<GroceryItem>.from(category.items)
          ..removeWhere((item) => item.itemId == itemId);
      
      // If no items left in category, remove the category
      if (updatedItems.isEmpty) {
        final updatedCategories = List<GroceryCategory>.from(groceryList.categories)
            ..removeAt(categoryIndex);
        
        await _firebaseService.updateDocument(
          '${Constants.groceryListsCollection}/$groceryListId',
          {
            'categories': updatedCategories.map((c) => c.toMap()).toList(),
            'lastModified': Timestamp.fromDate(DateTime.now()),
          },
        );
      } else {
        // Update the category with the remaining items
        final updatedCategory = GroceryCategory(
          categoryId: categoryId,
          name: category.name,
          items: updatedItems,
          order: category.order,
        );
        
        final updatedCategories = List<GroceryCategory>.from(groceryList.categories);
        updatedCategories[categoryIndex] = updatedCategory;
        
        await _firebaseService.updateDocument(
          '${Constants.groceryListsCollection}/$groceryListId',
          {
            'categories': updatedCategories.map((c) => c.toMap()).toList(),
            'lastModified': Timestamp.fromDate(DateTime.now()),
          },
        );
      }
    } catch (e) {
      throw FirebaseServiceException('Failed to remove item from grocery list', e);
    }
  }
  
  /// Stream a single grocery list by ID
  Stream<GroceryList?> streamGroceryList(String groceryListId) {
    try {
      return _firebaseService
          .streamDocument('${Constants.groceryListsCollection}/$groceryListId')
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return GroceryList.fromMap(snapshot.data() as Map<String, dynamic>);
          });
    } catch (e) {
      throw FirebaseServiceException('Failed to stream grocery list with ID: $groceryListId', e);
    }
  }
  
  /// Stream all grocery lists for a user
  Stream<List<GroceryList>> streamGroceryListsByUser(String userId) {
    try {
      final queryModifiers = [
        (Query query) => query.where('userId', isEqualTo: userId),
        (Query query) => query.orderBy('lastModified', descending: true),
      ];
      
      return _firebaseService
          .streamCollection(Constants.groceryListsCollection, queryModifiers: queryModifiers)
          .map((snapshot) => snapshot.docs
              .map((doc) => GroceryList.fromMap(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw FirebaseServiceException('Failed to stream grocery lists for user: $userId', e);
    }
  }
} 