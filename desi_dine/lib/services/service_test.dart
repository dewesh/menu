import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'services.dart';

/// Utility class to test all Firebase service operations
class ServiceTest {
  /// Variable to store test results
  static final List<String> testResults = [];
  
  /// Test all services and return test results
  static Future<List<String>> testAllServices() async {
    testResults.clear(); // Clear previous results
    
    print('🧪 SERVICE TEST: Starting all service tests...');
    testResults.add('Starting all service tests...');
    
    // Test all services
    try {
      await _testFirebaseConnection();
      await _testUserService();
      await _testMealService();
      await _testIngredientService();
      await _testGroceryService();
      
      print('✅ SERVICE TEST: All service tests completed successfully!');
      testResults.add('✅ SERVICE TEST: All service tests completed successfully!');
    } catch (e) {
      print('❌ SERVICE TEST: Tests failed with error: $e');
      testResults.add('❌ SERVICE TEST: Tests failed with error: $e');
    }
    
    return testResults;
  }
  
  /// Test basic Firebase connection
  static Future<void> _testFirebaseConnection() async {
    try {
      print('🧪 SERVICE TEST: Testing Firebase connection...');
      testResults.add('Testing Firebase connection...');
      
      // Get Firestore instance
      final firestore = FirebaseService.instance.firestore;
      
      // Try a simple operation
      await firestore.collection('_test_connection').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'testValue': 'This is a test',
      });
      
      // Fetch the document to verify it was created
      final testDoc = await firestore.collection('_test_connection').doc('test').get();
      if (testDoc.exists) {
        print('✅ SERVICE TEST: Firebase connection successful!');
        testResults.add('✅ SERVICE TEST: Firebase connection successful!');
      } else {
        throw Exception('Test document was not created');
      }
      
      // Clean up
      await firestore.collection('_test_connection').doc('test').delete();
    } catch (e) {
      print('❌ SERVICE TEST: Firebase connection test failed: $e');
      testResults.add('❌ SERVICE TEST: Firebase connection test failed: $e');
      throw e;
    }
  }
  
  /// Test UserService
  static Future<void> _testUserService() async {
    try {
      print('🧪 SERVICE TEST: Testing UserService...');
      testResults.add('Testing UserService...');
      
      final userService = UserService.instance;
      
      // Create test user data
      final testUser = User(
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        systemPreferences: SystemPreferences(
          isDarkMode: true,
          familySize: 4,
          dietaryPreferences: const ['vegetarian'],
          cuisinePreferences: const ['north-indian', 'south-indian'],
          familyMembers: [
            FamilyMember(name: 'Test Member', age: 30, dietaryRestrictions: const ['lactose-free']),
          ],
        ),
      );
      
      // Test Create
      print('🧪 SERVICE TEST: Creating test user...');
      testResults.add('Creating test user...');
      final createdUser = await userService.createUser(testUser);
      testResults.add('User created with ID: ${createdUser.userId}');
      
      // Test Read
      print('🧪 SERVICE TEST: Reading test user...');
      testResults.add('Reading test user...');
      final readUser = await userService.getUserById(createdUser.userId);
      if (readUser != null && readUser.name == testUser.name) {
        print('✅ SERVICE TEST: User read successful!');
        testResults.add('✅ SERVICE TEST: User read successful!');
      } else {
        throw Exception('User read failed or data mismatch');
      }
      
      // Test Update
      print('🧪 SERVICE TEST: Updating test user...');
      testResults.add('Updating test user...');
      final updatedUser = User(
        userId: createdUser.userId,
        name: 'Updated Test User',
        email: testUser.email,
        createdAt: testUser.createdAt,
        lastModified: DateTime.now(),
        systemPreferences: testUser.systemPreferences,
      );
      await userService.updateUser(updatedUser);
      
      // Verify update
      final verifyUser = await userService.getUserById(createdUser.userId);
      if (verifyUser != null && verifyUser.name == 'Updated Test User') {
        print('✅ SERVICE TEST: User update successful!');
        testResults.add('✅ SERVICE TEST: User update successful!');
      } else {
        throw Exception('User update failed or data mismatch');
      }
      
      // Test Delete
      print('🧪 SERVICE TEST: Deleting test user...');
      testResults.add('Deleting test user...');
      await userService.deleteUser(createdUser.userId);
      
      // Verify deletion
      final deletedUser = await userService.getUserById(createdUser.userId);
      if (deletedUser == null) {
        print('✅ SERVICE TEST: User deletion successful!');
        testResults.add('✅ SERVICE TEST: User deletion successful!');
      } else {
        throw Exception('User deletion failed');
      }
      
      print('✅ SERVICE TEST: UserService tests completed successfully!');
      testResults.add('✅ SERVICE TEST: UserService tests completed successfully!');
    } catch (e) {
      print('❌ SERVICE TEST: UserService test failed: $e');
      testResults.add('❌ SERVICE TEST: UserService test failed: $e');
      throw e;
    }
  }
  
  /// Test MealService
  static Future<void> _testMealService() async {
    try {
      print('🧪 SERVICE TEST: Testing MealService...');
      testResults.add('Testing MealService...');
      
      final mealService = MealService.instance;
      
      // Create test meal data
      final testMeal = Meal(
        mealId: 'test_meal_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Butter Chicken',
        description: 'A delicious test meal',
        type: 'dinner',
        cuisineType: 'north-indian',
        preparationTime: 20,
        cookingTime: 30,
        difficultyLevel: 'medium',
        nutritionalInfo: NutritionalInfo(
          calories: 450,
          protein: 25.0,
          carbs: 30.0,
          fat: 20.0,
          fiber: 3.0,
        ),
        recipe: Recipe(
          ingredients: [
            RecipeIngredient(
              ingredientId: 'chicken',
              name: 'Chicken',
              quantity: 500.0,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredientId: 'butter',
              name: 'Butter',
              quantity: 50.0,
              unit: 'g',
            ),
          ],
          preparationSteps: [
            PreparationStep(
              stepNumber: 1,
              description: 'Marinate the chicken',
            ),
            PreparationStep(
              stepNumber: 2,
              description: 'Cook with butter and spices',
            ),
          ],
          servingSize: 4,
        ),
        tags: const ['creamy', 'spicy'],
        suitableHealthConditions: const [],
        seasonalRelevance: 'year-round',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
      
      // Test Create
      print('🧪 SERVICE TEST: Creating test meal...');
      testResults.add('Creating test meal...');
      final createdMeal = await mealService.createMeal(testMeal);
      testResults.add('Meal created with ID: ${createdMeal.mealId}');
      
      // Test Read
      print('🧪 SERVICE TEST: Reading test meal...');
      testResults.add('Reading test meal...');
      final readMeal = await mealService.getMealById(createdMeal.mealId);
      if (readMeal != null && readMeal.name == testMeal.name) {
        print('✅ SERVICE TEST: Meal read successful!');
        testResults.add('✅ SERVICE TEST: Meal read successful!');
      } else {
        throw Exception('Meal read failed or data mismatch');
      }
      
      // Test Update
      print('🧪 SERVICE TEST: Updating test meal...');
      testResults.add('Updating test meal...');
      final updatedMeal = createdMeal.copyWith(
        name: 'Updated Test Meal',
      );
      await mealService.updateMeal(updatedMeal);
      
      // Verify update
      final verifyMeal = await mealService.getMealById(createdMeal.mealId);
      if (verifyMeal != null && verifyMeal.name == 'Updated Test Meal') {
        print('✅ SERVICE TEST: Meal update successful!');
        testResults.add('✅ SERVICE TEST: Meal update successful!');
      } else {
        throw Exception('Meal update failed or data mismatch');
      }
      
      // Test Delete
      print('🧪 SERVICE TEST: Deleting test meal...');
      testResults.add('Deleting test meal...');
      await mealService.deleteMeal(createdMeal.mealId);
      
      // Verify deletion
      final deletedMeal = await mealService.getMealById(createdMeal.mealId);
      if (deletedMeal == null) {
        print('✅ SERVICE TEST: Meal deletion successful!');
        testResults.add('✅ SERVICE TEST: Meal deletion successful!');
      } else {
        throw Exception('Meal deletion failed');
      }
      
      print('✅ SERVICE TEST: MealService tests completed successfully!');
      testResults.add('✅ SERVICE TEST: MealService tests completed successfully!');
    } catch (e) {
      print('❌ SERVICE TEST: MealService test failed: $e');
      testResults.add('❌ SERVICE TEST: MealService test failed: $e');
      throw e;
    }
  }
  
  /// Test IngredientService
  static Future<void> _testIngredientService() async {
    try {
      print('🧪 SERVICE TEST: Testing IngredientService...');
      testResults.add('Testing IngredientService...');
      
      final ingredientService = IngredientService.instance;
      
      // Create test ingredient data
      final testIngredient = Ingredient(
        ingredientId: 'test_ingredient_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Garam Masala',
        category: 'spice',
        description: 'A test spice blend',
        isVegetarian: true,
        isVegan: true,
        isGlutenFree: true,
        tags: const ['spicy', 'aromatic'],
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
      
      // Test Create
      print('🧪 SERVICE TEST: Creating test ingredient...');
      testResults.add('Creating test ingredient...');
      final createdIngredient = await ingredientService.createIngredient(testIngredient);
      testResults.add('Ingredient created with ID: ${createdIngredient.ingredientId}');
      
      // Test Read
      print('🧪 SERVICE TEST: Reading test ingredient...');
      testResults.add('Reading test ingredient...');
      final readIngredient = await ingredientService.getIngredientById(createdIngredient.ingredientId);
      if (readIngredient != null && readIngredient.name == testIngredient.name) {
        print('✅ SERVICE TEST: Ingredient read successful!');
        testResults.add('✅ SERVICE TEST: Ingredient read successful!');
      } else {
        throw Exception('Ingredient read failed or data mismatch');
      }
      
      // Test Update
      print('🧪 SERVICE TEST: Updating test ingredient...');
      testResults.add('Updating test ingredient...');
      final updatedIngredient = createdIngredient.copyWith(
        name: 'Updated Test Ingredient',
      );
      await ingredientService.updateIngredient(updatedIngredient);
      
      // Verify update
      final verifyIngredient = await ingredientService.getIngredientById(createdIngredient.ingredientId);
      if (verifyIngredient != null && verifyIngredient.name == 'Updated Test Ingredient') {
        print('✅ SERVICE TEST: Ingredient update successful!');
        testResults.add('✅ SERVICE TEST: Ingredient update successful!');
      } else {
        throw Exception('Ingredient update failed or data mismatch');
      }
      
      // Test Delete
      print('🧪 SERVICE TEST: Deleting test ingredient...');
      testResults.add('Deleting test ingredient...');
      await ingredientService.deleteIngredient(createdIngredient.ingredientId);
      
      // Verify deletion
      final deletedIngredient = await ingredientService.getIngredientById(createdIngredient.ingredientId);
      if (deletedIngredient == null) {
        print('✅ SERVICE TEST: Ingredient deletion successful!');
        testResults.add('✅ SERVICE TEST: Ingredient deletion successful!');
      } else {
        throw Exception('Ingredient deletion failed');
      }
      
      print('✅ SERVICE TEST: IngredientService tests completed successfully!');
      testResults.add('✅ SERVICE TEST: IngredientService tests completed successfully!');
    } catch (e) {
      print('❌ SERVICE TEST: IngredientService test failed: $e');
      testResults.add('❌ SERVICE TEST: IngredientService test failed: $e');
      throw e;
    }
  }
  
  /// Test GroceryService
  static Future<void> _testGroceryService() async {
    try {
      print('🧪 SERVICE TEST: Testing GroceryService...');
      testResults.add('Testing GroceryService...');
      
      final groceryService = GroceryService.instance;
      
      // Create test grocery list data
      final testGroceryList = GroceryList(
        groceryListId: 'test_grocery_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        title: 'Test Grocery List',
        categories: [
          GroceryCategory(
            categoryId: 'test_cat_1',
            name: 'Vegetables',
            items: [
              GroceryItem(
                itemId: 'test_item_1',
                name: 'Onion',
                quantity: 2.0,
                unit: 'kg',
              ),
              GroceryItem(
                itemId: 'test_item_2',
                name: 'Tomato',
                quantity: 500.0,
                unit: 'g',
              ),
            ],
            order: 1,
          ),
        ],
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );
      
      // Test Create
      print('🧪 SERVICE TEST: Creating test grocery list...');
      testResults.add('Creating test grocery list...');
      final createdGroceryList = await groceryService.createGroceryList(testGroceryList);
      testResults.add('Grocery list created with ID: ${createdGroceryList.groceryListId}');
      
      // Test Read
      print('🧪 SERVICE TEST: Reading test grocery list...');
      testResults.add('Reading test grocery list...');
      final readGroceryList = await groceryService.getGroceryListById(createdGroceryList.groceryListId);
      if (readGroceryList != null && readGroceryList.title == testGroceryList.title) {
        print('✅ SERVICE TEST: Grocery list read successful!');
        testResults.add('✅ SERVICE TEST: Grocery list read successful!');
      } else {
        throw Exception('Grocery list read failed or data mismatch');
      }
      
      // Test Adding Item
      print('🧪 SERVICE TEST: Adding item to grocery list...');
      testResults.add('Adding item to grocery list...');
      final newItem = GroceryItem(
        itemId: 'test_new_item',
        name: 'Potato',
        quantity: 1.0,
        unit: 'kg',
      );
      await groceryService.addItemToGroceryList(
        createdGroceryList.groceryListId,
        createdGroceryList.categories[0].categoryId,
        newItem,
      );
      
      // Verify item added
      final verifyAddedItem = await groceryService.getGroceryListById(createdGroceryList.groceryListId);
      final hasNewItem = verifyAddedItem!.categories[0].items.any((item) => item.name == 'Potato');
      if (hasNewItem) {
        print('✅ SERVICE TEST: Adding grocery item successful!');
        testResults.add('✅ SERVICE TEST: Adding grocery item successful!');
      } else {
        throw Exception('Adding grocery item failed');
      }
      
      // Test Update Item Status
      print('🧪 SERVICE TEST: Updating item status in grocery list...');
      testResults.add('Updating item status in grocery list...');
      await groceryService.updateItemStatus(
        createdGroceryList.groceryListId,
        createdGroceryList.categories[0].categoryId,
        newItem.itemId,
        true, // Mark as purchased
      );
      
      // Verify item status updated
      final verifyStatusUpdate = await groceryService.getGroceryListById(createdGroceryList.groceryListId);
      final updatedItem = verifyStatusUpdate!.categories[0].items.firstWhere(
        (item) => item.itemId == newItem.itemId,
      );
      if (updatedItem.isPurchased) {
        print('✅ SERVICE TEST: Updating grocery item status successful!');
        testResults.add('✅ SERVICE TEST: Updating grocery item status successful!');
      } else {
        throw Exception('Updating grocery item status failed');
      }
      
      // Test Delete
      print('🧪 SERVICE TEST: Deleting test grocery list...');
      testResults.add('Deleting test grocery list...');
      await groceryService.deleteGroceryList(createdGroceryList.groceryListId);
      
      // Verify deletion
      final deletedGroceryList = await groceryService.getGroceryListById(createdGroceryList.groceryListId);
      if (deletedGroceryList == null) {
        print('✅ SERVICE TEST: Grocery list deletion successful!');
        testResults.add('✅ SERVICE TEST: Grocery list deletion successful!');
      } else {
        throw Exception('Grocery list deletion failed');
      }
      
      print('✅ SERVICE TEST: GroceryService tests completed successfully!');
      testResults.add('✅ SERVICE TEST: GroceryService tests completed successfully!');
    } catch (e) {
      print('❌ SERVICE TEST: GroceryService test failed: $e');
      testResults.add('❌ SERVICE TEST: GroceryService test failed: $e');
      throw e;
    }
  }
} 