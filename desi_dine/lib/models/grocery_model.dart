import 'package:cloud_firestore/cloud_firestore.dart';

/// Grocery list model for shopping
class GroceryList {
  final String groceryListId;
  final String userId;
  final String title;
  final String? mealPlanId; // Reference to associated meal plan (if any)
  final List<GroceryCategory> categories;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool isShared; // Whether the list is shared with others

  GroceryList({
    required this.groceryListId,
    required this.userId,
    required this.title,
    this.mealPlanId,
    required this.categories,
    required this.createdAt,
    required this.lastModified,
    this.isShared = false,
  });

  /// Get all items across all categories
  List<GroceryItem> get allItems {
    return categories.expand((category) => category.items).toList();
  }

  /// Get count of purchased items
  int get purchasedItemCount {
    return allItems.where((item) => item.isPurchased).length;
  }

  /// Get total count of items
  int get totalItemCount {
    return allItems.length;
  }

  /// Check if all items are purchased
  bool get isComplete {
    return totalItemCount > 0 && purchasedItemCount == totalItemCount;
  }

  /// Convert GroceryList object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groceryListId': groceryListId,
      'userId': userId,
      'title': title,
      'mealPlanId': mealPlanId,
      'categories': categories.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
      'isShared': isShared,
    };
  }

  /// Create GroceryList object from Firestore document
  factory GroceryList.fromMap(Map<String, dynamic> map) {
    return GroceryList(
      groceryListId: map['groceryListId'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      mealPlanId: map['mealPlanId'] as String?,
      categories: List<GroceryCategory>.from(
        (map['categories'] as List).map(
          (x) => GroceryCategory.fromMap(x),
        ),
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: (map['lastModified'] as Timestamp).toDate(),
      isShared: map['isShared'] as bool? ?? false,
    );
  }
}

/// Category for organizing grocery items
class GroceryCategory {
  final String categoryId;
  final String name;
  final List<GroceryItem> items;
  final int order; // For custom sorting

  GroceryCategory({
    required this.categoryId,
    required this.name,
    required this.items,
    this.order = 0,
  });

  /// Convert GroceryCategory object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'items': items.map((x) => x.toMap()).toList(),
      'order': order,
    };
  }

  /// Create GroceryCategory object from Firestore document
  factory GroceryCategory.fromMap(Map<String, dynamic> map) {
    return GroceryCategory(
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      items: List<GroceryItem>.from(
        (map['items'] as List).map(
          (x) => GroceryItem.fromMap(x),
        ),
      ),
      order: map['order'] as int? ?? 0,
    );
  }
}

/// Individual grocery item
class GroceryItem {
  final String itemId;
  final String name;
  final double quantity;
  final String unit;
  final String? notes;
  final String? ingredientId; // Reference to Ingredient if applicable
  final bool isPurchased;
  final int priority; // 0 = normal, 1 = important, 2 = urgent

  GroceryItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.notes,
    this.ingredientId,
    this.isPurchased = false,
    this.priority = 0,
  });

  /// Convert GroceryItem object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'ingredientId': ingredientId,
      'isPurchased': isPurchased,
      'priority': priority,
    };
  }

  /// Create GroceryItem object from Firestore document
  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      itemId: map['itemId'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      notes: map['notes'] as String?,
      ingredientId: map['ingredientId'] as String?,
      isPurchased: map['isPurchased'] as bool? ?? false,
      priority: map['priority'] as int? ?? 0,
    );
  }
}

/// Meal plan model (used in associations with grocery lists)
class GroceryMealPlan {
  final String mealPlanId;
  final String userId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<GroceryMealPlanDay> days;
  final DateTime createdAt;
  final DateTime lastModified;

  GroceryMealPlan({
    required this.mealPlanId,
    required this.userId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.createdAt,
    required this.lastModified,
  });

  /// Convert GroceryMealPlan object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mealPlanId': mealPlanId,
      'userId': userId,
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'days': days.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastModified': Timestamp.fromDate(lastModified),
    };
  }

  /// Create GroceryMealPlan object from Firestore document
  factory GroceryMealPlan.fromMap(Map<String, dynamic> map) {
    return GroceryMealPlan(
      mealPlanId: map['mealPlanId'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      days: List<GroceryMealPlanDay>.from(
        (map['days'] as List).map(
          (x) => GroceryMealPlanDay.fromMap(x),
        ),
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastModified: (map['lastModified'] as Timestamp).toDate(),
    );
  }
}

/// Day in a meal plan
class GroceryMealPlanDay {
  final DateTime date;
  final List<GroceryMealPlanMeal> meals;

  GroceryMealPlanDay({
    required this.date,
    required this.meals,
  });

  /// Convert GroceryMealPlanDay object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'meals': meals.map((x) => x.toMap()).toList(),
    };
  }

  /// Create GroceryMealPlanDay object from Firestore document
  factory GroceryMealPlanDay.fromMap(Map<String, dynamic> map) {
    return GroceryMealPlanDay(
      date: (map['date'] as Timestamp).toDate(),
      meals: List<GroceryMealPlanMeal>.from(
        (map['meals'] as List).map(
          (x) => GroceryMealPlanMeal.fromMap(x),
        ),
      ),
    );
  }
}

/// Meal in a meal plan
class GroceryMealPlanMeal {
  final String mealId;
  final String mealType; // breakfast, lunch, dinner, snack
  final int servings;
  final bool isCompleted;

  GroceryMealPlanMeal({
    required this.mealId,
    required this.mealType,
    required this.servings,
    this.isCompleted = false,
  });

  /// Convert GroceryMealPlanMeal object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'mealId': mealId,
      'mealType': mealType,
      'servings': servings,
      'isCompleted': isCompleted,
    };
  }

  /// Create GroceryMealPlanMeal object from Firestore document
  factory GroceryMealPlanMeal.fromMap(Map<String, dynamic> map) {
    return GroceryMealPlanMeal(
      mealId: map['mealId'] as String,
      mealType: map['mealType'] as String,
      servings: map['servings'] as int,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
} 