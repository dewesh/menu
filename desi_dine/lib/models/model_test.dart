import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'meal_model.dart' as meal;  // Import with a prefix to avoid conflicts

/// Utility class to test all data models
class ModelTest {
  // Variable to store test results
  static final List<String> testResults = [];
  
  /// Test all models and return test results
  static List<String> testAllModels() {
    testResults.clear(); // Clear previous results
    
    print('🧪 MODEL TEST: Starting all model tests...');
    testResults.add('Starting all model tests...');
    
    // Test all models
    _testUserModel();
    _testMealModel();
    _testIngredientModel();
    _testGroceryModel();
    
    print('✅ MODEL TEST: All model tests completed successfully!');
    testResults.add('✅ MODEL TEST: All model tests completed successfully!');
    
    return testResults;
  }
  
  /// Test User model and related models
  static void _testUserModel() {
    print('🧪 MODEL TEST: Testing User model...');
    testResults.add('Testing User model...');
    
    // Create test data
    final now = DateTime.now();
    
    final systemPrefs = SystemPreferences(
      themeMode: 'dark',
      notificationsEnabled: true,
    );
    
    final tastePrefs = TastePreferences(
      spiceLevel: 4,
      sweetness: 3,
      sourness: 2,
    );
    
    final customPref = CustomPreference(
      name: 'Low Salt',
      description: 'Minimize salt in all recipes',
    );
    
    final cuisinePref = CuisinePreference(
      cuisineType: 'North Indian',
      frequencyPreference: 'daily',
    );
    
    final userPrefs = UserPreferences(
      userId: 'user123',
      dietaryType: 'vegetarian',
      customDietaryPreferences: [customPref],
      cuisinePreferences: [cuisinePref],
      tastePreferences: tastePrefs,
      avoidedIngredients: ['garlic', 'onion'],
    );
    
    final dietaryPrefs = FamilyMemberDietaryPreferences(
      dietaryType: 'vegan',
      customDietaryPreferences: ['No mushrooms'],
    );
    
    final healthCondition = HealthCondition(
      condition: 'diabetes',
      severity: 'moderate',
      dietaryNotes: 'Low sugar and carbs',
    );
    
    final familyMember = FamilyMember(
      userId: 'user123',
      memberId: 'member1',
      name: 'John Doe',
      age: 35,
      relationship: 'self',
      dietaryPreferences: dietaryPrefs,
      healthConditions: [healthCondition],
      avoidedIngredients: ['peanuts'],
    );
    
    final user = User(
      userId: 'user123',
      name: 'John Doe',
      email: 'john@example.com',
      createdAt: now,
      lastModified: now,
      systemPreferences: systemPrefs,
    );
    
    // Convert to map and back
    final userMap = user.toMap();
    final userFromMap = User.fromMap(userMap);
    
    final userPrefsMap = userPrefs.toMap();
    final userPrefsFromMap = UserPreferences.fromMap(userPrefsMap);
    
    final familyMemberMap = familyMember.toMap();
    final familyMemberFromMap = FamilyMember.fromMap(familyMemberMap);
    
    // Log results for debugging
    final result1 = 'User conversion: ${user.userId == userFromMap.userId ? "✅ SUCCESS" : "❌ FAILED"}';
    final result2 = 'UserPreferences conversion: ${userPrefs.dietaryType == userPrefsFromMap.dietaryType ? "✅ SUCCESS" : "❌ FAILED"}';
    final result3 = 'FamilyMember conversion: ${familyMember.name == familyMemberFromMap.name ? "✅ SUCCESS" : "❌ FAILED"}';
    
    print('🧪 MODEL TEST: $result1');
    print('🧪 MODEL TEST: $result2');
    print('🧪 MODEL TEST: $result3');
    
    testResults.add(result1);
    testResults.add(result2);
    testResults.add(result3);
    
    print('✅ MODEL TEST: User model test completed');
    testResults.add('User model test completed');
  }
  
  /// Test Meal model and related models
  static void _testMealModel() {
    print('🧪 MODEL TEST: Testing Meal model...');
    testResults.add('Testing Meal model...');
    
    final now = DateTime.now();
    
    // Create test nutritional info
    final nutritionalInfo = meal.NutritionalInfo(
      calories: 450,
      protein: 25.0,
      carbs: 30.0,
      fat: 20.0,
      fiber: 3.0,
    );
    
    final recipeIngredient1 = meal.RecipeIngredient(
      ingredientId: 'ing123',
      name: 'Rice',
      quantity: 200.0,
      unit: 'g',
    );
    
    final recipeIngredient2 = meal.RecipeIngredient(
      ingredientId: 'ing456',
      name: 'Lentils',
      quantity: 100.0,
      unit: 'g',
      isOptional: false,
    );
    
    final step1 = meal.PreparationStep(
      stepNumber: 1,
      description: 'Wash rice and lentils thoroughly.',
    );
    
    final step2 = meal.PreparationStep(
      stepNumber: 2,
      description: 'Boil water and add rice and lentils.',
      timeTakenMinutes: 20,
    );
    
    final recipe = meal.Recipe(
      ingredients: [recipeIngredient1, recipeIngredient2],
      preparationSteps: [step1, step2],
      servingSize: 4,
      notes: 'Best served hot with a side of yogurt.',
    );
    
    final testMeal = meal.Meal(
      mealId: 'meal123',
      name: 'Butter Chicken',
      description: 'A classic Indian dish',
      type: 'dinner',
      cuisineType: 'north-indian',
      preparationTime: 20,
      cookingTime: 30,
      difficultyLevel: 'medium',
      nutritionalInfo: nutritionalInfo,
      recipe: recipe,
      tags: const ['creamy', 'spicy'],
      suitableHealthConditions: const [],
      seasonalRelevance: 'year-round',
      createdAt: now,
      lastModified: now,
    );
    
    // Convert to map and back
    final mealMap = testMeal.toMap();
    final mealFromMap = meal.Meal.fromMap(mealMap);
    
    // Log results for debugging
    final result1 = 'Meal conversion: ${testMeal.name == mealFromMap.name ? "✅ SUCCESS" : "❌ FAILED"}';
    final result2 = 'Recipe ingredients count: ${testMeal.recipe.ingredients.length == mealFromMap.recipe.ingredients.length ? "✅ SUCCESS" : "❌ FAILED"}';
    final result3 = 'Preparation steps count: ${testMeal.recipe.preparationSteps.length == mealFromMap.recipe.preparationSteps.length ? "✅ SUCCESS" : "❌ FAILED"}';
    
    print('🧪 MODEL TEST: $result1');
    print('🧪 MODEL TEST: $result2');
    print('🧪 MODEL TEST: $result3');
    
    testResults.add(result1);
    testResults.add(result2);
    testResults.add(result3);
    
    print('✅ MODEL TEST: Meal model test completed');
    testResults.add('Meal model test completed');
  }
  
  /// Test Ingredient model
  static void _testIngredientModel() {
    print('🧪 MODEL TEST: Testing Ingredient model...');
    testResults.add('Testing Ingredient model...');
    
    // Create test data
    final now = DateTime.now();
    
    final nutritionalInfo = IngredientNutritionalInfo(
      calories: 130,
      protein: 2.7,
      carbs: 28.0,
      fat: 0.3,
      fiber: 1.4,
      standardServingSize: 100.0,
      standardServingUnit: 'g',
    );
    
    final purchaseInfo = PurchaseInfo(
      standardUnit: 'kg',
      estimatedCostPerUnit: 3.5,
      commonPurchaseForms: ['loose', 'packaged'],
      seasonalAvailability: 'year-round',
      shelfLife: '6-12 months in airtight container',
      storageRecommendation: 'Store in a cool, dry place',
    );
    
    final ingredient = Ingredient(
      ingredientId: 'ing123',
      name: 'Basmati Rice',
      category: 'grain',
      description: 'Long grain aromatic rice',
      nutritionalInfo: nutritionalInfo,
      purchaseInfo: purchaseInfo,
      tags: ['staple', 'gluten-free'],
      isVegetarian: true,
      isVegan: true,
      isGlutenFree: true,
      createdAt: now,
      lastModified: now,
    );
    
    // Convert to map and back
    final ingredientMap = ingredient.toMap();
    final ingredientFromMap = Ingredient.fromMap(ingredientMap);
    
    // Log results for debugging
    final result1 = 'Ingredient conversion: ${ingredient.name == ingredientFromMap.name ? "✅ SUCCESS" : "❌ FAILED"}';
    final result2 = 'Nutritional info conversion: ${ingredient.nutritionalInfo?.calories == ingredientFromMap.nutritionalInfo?.calories ? "✅ SUCCESS" : "❌ FAILED"}';
    final result3 = 'Purchase info conversion: ${ingredient.purchaseInfo?.standardUnit == ingredientFromMap.purchaseInfo?.standardUnit ? "✅ SUCCESS" : "❌ FAILED"}';
    
    print('🧪 MODEL TEST: $result1');
    print('🧪 MODEL TEST: $result2');
    print('🧪 MODEL TEST: $result3');
    
    testResults.add(result1);
    testResults.add(result2);
    testResults.add(result3);
    
    print('✅ MODEL TEST: Ingredient model test completed');
    testResults.add('Ingredient model test completed');
  }
  
  /// Test Grocery model
  static void _testGroceryModel() {
    print('🧪 MODEL TEST: Testing Grocery model...');
    testResults.add('Testing Grocery model...');
    
    // Create test data
    final now = DateTime.now();
    
    final groceryItem1 = GroceryItem(
      itemId: 'item123',
      name: 'Basmati Rice',
      quantity: 2.0,
      unit: 'kg',
      ingredientId: 'ing123',
      priority: 1,
    );
    
    final groceryItem2 = GroceryItem(
      itemId: 'item456',
      name: 'Red Lentils',
      quantity: 500.0,
      unit: 'g',
      isPurchased: true,
    );
    
    final category1 = GroceryCategory(
      categoryId: 'cat1',
      name: 'Grains',
      items: [groceryItem1],
    );
    
    final category2 = GroceryCategory(
      categoryId: 'cat2',
      name: 'Lentils',
      items: [groceryItem2],
    );
    
    final groceryList = GroceryList(
      groceryListId: 'list123',
      userId: 'user123',
      title: 'Weekly Grocery',
      categories: [category1, category2],
      createdAt: now,
      lastModified: now,
    );
    
    // Test MealPlan models
    final mealPlanMeal1 = GroceryMealPlanMeal(
      mealId: 'meal123',
      mealType: 'breakfast',
      servings: 2,
    );
    
    final mealPlanMeal2 = GroceryMealPlanMeal(
      mealId: 'meal456',
      mealType: 'dinner',
      servings: 4,
      isCompleted: true,
    );
    
    final mealPlanDay = GroceryMealPlanDay(
      date: now,
      meals: [mealPlanMeal1, mealPlanMeal2],
    );
    
    final mealPlan = GroceryMealPlan(
      mealPlanId: 'plan123',
      userId: 'user123',
      title: 'This Week\'s Plan',
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      days: [mealPlanDay],
      createdAt: now,
      lastModified: now,
    );
    
    // Convert to map and back
    final groceryListMap = groceryList.toMap();
    final groceryListFromMap = GroceryList.fromMap(groceryListMap);
    
    final mealPlanMap = mealPlan.toMap();
    final mealPlanFromMap = GroceryMealPlan.fromMap(mealPlanMap);
    
    // Log results for debugging
    final result1 = 'GroceryList conversion: ${groceryList.title == groceryListFromMap.title ? "✅ SUCCESS" : "❌ FAILED"}';
    final result2 = 'Categories count: ${groceryList.categories.length == groceryListFromMap.categories.length ? "✅ SUCCESS" : "❌ FAILED"}';
    final result3 = 'Items count: ${groceryList.allItems.length == groceryListFromMap.allItems.length ? "✅ SUCCESS" : "❌ FAILED"}';
    final result4 = 'MealPlan conversion: ${mealPlan.title == mealPlanFromMap.title ? "✅ SUCCESS" : "❌ FAILED"}';
    final result5 = 'MealPlanDay count: ${mealPlan.days.length == mealPlanFromMap.days.length ? "✅ SUCCESS" : "❌ FAILED"}';
    
    print('🧪 MODEL TEST: $result1');
    print('🧪 MODEL TEST: $result2');
    print('🧪 MODEL TEST: $result3');
    print('🧪 MODEL TEST: $result4');
    print('🧪 MODEL TEST: $result5');
    
    testResults.add(result1);
    testResults.add(result2);
    testResults.add(result3);
    testResults.add(result4);
    testResults.add(result5);
    
    print('✅ MODEL TEST: Grocery model test completed');
    testResults.add('Grocery model test completed');
  }
} 