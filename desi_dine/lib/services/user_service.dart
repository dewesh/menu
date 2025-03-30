import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';
import 'meal_plan_service.dart';

/// Service for User model operations
class UserService {
  static final UserService _instance = UserService._internal();
  
  /// Access the singleton instance
  static UserService get instance => _instance;
  
  /// Firebase service reference
  final FirebaseService _firebaseService = FirebaseService.instance;
  
  // Private constructor for singleton pattern
  UserService._internal();
  
  /// Create a new user
  Future<User> createUser(User user) async {
    try {
      // Generate a document ID if not provided
      String userId = user.userId.isEmpty ? _firebaseService.generateId(Constants.usersCollection) : user.userId;
      
      // Create a new user with the generated ID
      final userWithId = User(
        userId: userId,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        lastModified: DateTime.now(),
        systemPreferences: user.systemPreferences,
      );
      
      // Save to Firestore
      await _firebaseService.setDocument(
        '${Constants.usersCollection}/$userId',
        userWithId.toMap(),
      );
      
      return userWithId;
    } catch (e) {
      throw FirebaseServiceException('Failed to create user', e);
    }
  }
  
  /// Get a user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firebaseService.getDocument('${Constants.usersCollection}/$userId');
      
      if (!doc.exists) {
        return null;
      }
      
      return User.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw FirebaseServiceException('Failed to get user with ID: $userId', e);
    }
  }
  
  /// Update an existing user
  Future<void> updateUser(User user) async {
    try {
      // Create an updated user with the current timestamp
      final updatedUser = User(
        userId: user.userId,
        name: user.name,
        email: user.email,
        createdAt: user.createdAt,
        lastModified: DateTime.now(),
        systemPreferences: user.systemPreferences,
      );
      
      await _firebaseService.updateDocument(
        '${Constants.usersCollection}/${user.userId}',
        updatedUser.toMap(),
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to update user with ID: ${user.userId}', e);
    }
  }
  
  /// Delete a user by ID
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseService.deleteDocument('${Constants.usersCollection}/$userId');
    } catch (e) {
      throw FirebaseServiceException('Failed to delete user with ID: $userId', e);
    }
  }
  
  /// Get all users (be careful with this in production)
  Future<List<User>> getAllUsers() async {
    try {
      final querySnapshot = await _firebaseService.getCollection(Constants.usersCollection);
      
      return querySnapshot.docs
          .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get all users', e);
    }
  }
  
  /// Stream a single user by ID
  Stream<User?> streamUser(String userId) {
    try {
      return _firebaseService
          .streamDocument('${Constants.usersCollection}/$userId')
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return User.fromMap(snapshot.data() as Map<String, dynamic>);
          });
    } catch (e) {
      throw FirebaseServiceException('Failed to stream user with ID: $userId', e);
    }
  }
  
  /// Update user preferences
  Future<void> updateUserPreferences(String userId, SystemPreferences preferences) async {
    try {
      // Get current user data to detect changes
      final currentUser = await getUserById(userId);
      bool needsMealPlanUpdate = false;
      
      // Check if relevant preferences have changed
      if (currentUser != null && currentUser.systemPreferences != null) {
        final currentPrefs = currentUser.systemPreferences!;
        
        // Check if any meal plan relevant preferences changed
        needsMealPlanUpdate = 
            preferences.familySize != currentPrefs.familySize ||
            _listsDiffer(preferences.dietaryPreferences, currentPrefs.dietaryPreferences) ||
            _cuisinePreferencesDiffer(preferences.cuisinePreferences, currentPrefs.cuisinePreferences);
      }
      
      // Update user preferences in Firestore
      await _firebaseService.updateDocument(
        '${Constants.usersCollection}/$userId',
        {
          'systemPreferences': preferences.toMap(),
          'lastModified': Timestamp.fromDate(DateTime.now()),
        },
      );
      
      // If relevant preferences changed, update the meal plan
      if (needsMealPlanUpdate) {
        // Do this in the background without awaiting
        _updateUserMealPlan(userId, preferences);
      }
    } catch (e) {
      throw FirebaseServiceException('Failed to update preferences for user ID: $userId', e);
    }
  }
  
  /// Helper to check if two lists differ
  bool _listsDiffer<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) {
      return true;
    }
    
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Helper to check if cuisine preferences differ
  bool _cuisinePreferencesDiffer(
    List<CuisinePreference> list1, 
    List<CuisinePreference> list2
  ) {
    if (list1.length != list2.length) {
      return true;
    }
    
    for (final pref1 in list1) {
      bool found = false;
      for (final pref2 in list2) {
        if (pref1.cuisineType == pref2.cuisineType && 
            pref1.frequencyPreference == pref2.frequencyPreference) {
          found = true;
          break;
        }
      }
      if (!found) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Update meal plan based on new preferences
  Future<void> _updateUserMealPlan(String userId, SystemPreferences preferences) async {
    try {
      print('Updating meal plan for user $userId due to preference changes');
      print('Preferences: ${preferences.cuisinePreferences.length} cuisine preferences, ' +
            '${preferences.dietaryPreferences.length} dietary preferences, ' +
            'family size: ${preferences.familySize}');
      
      final mealPlanService = MealPlanService.instance;
      
      // This will either create a new plan or update the existing one
      // It should generate a 7-day meal plan
      print('Generating a 7-day meal plan for user $userId');
      
      final mealPlan = await mealPlanService.getOrCreateMealPlan(
        userId: userId,
        cuisinePreferences: preferences.cuisinePreferences,
        dietaryPreferences: preferences.dietaryPreferences,
        familySize: preferences.familySize,
      );
      
      print('Meal plan updated successfully. Day count: ${mealPlan.days.length}');
      print('Meal plan dates: ${mealPlan.days.keys.map((date) => date.toIso8601String().substring(0, 10)).join(', ')}');
    } catch (e) {
      print('Error updating meal plan after preference change: $e');
      // Don't throw - this is a background operation
    }
  }
} 