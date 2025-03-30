import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firebase_service.dart';

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
      await _firebaseService.updateDocument(
        '${Constants.usersCollection}/$userId',
        {
          'systemPreferences': preferences.toMap(),
          'lastModified': Timestamp.fromDate(DateTime.now()),
        },
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to update preferences for user ID: $userId', e);
    }
  }
} 