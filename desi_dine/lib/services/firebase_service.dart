import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Custom exception for Firebase operations
class FirebaseServiceException implements Exception {
  final String message;
  final dynamic error;

  FirebaseServiceException(this.message, [this.error]);

  @override
  String toString() => 'FirebaseServiceException: $message ${error != null ? '($error)' : ''}';
}

/// A service class to handle all Firebase Firestore operations.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  /// Access the singleton instance
  static FirebaseService get instance => _instance;
  
  /// The Firestore instance.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Private constructor for singleton pattern
  FirebaseService._internal();

  /// Get the Firestore instance directly
  FirebaseFirestore get firestore => _firestore;

  /// Get a collection reference.
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference.
  DocumentReference document(String path) {
    return _firestore.doc(path);
  }

  /// Add a document to a collection.
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      throw FirebaseServiceException('Failed to add document to $collection', e);
    }
  }

  /// Set a document in a collection with a specific ID.
  Future<void> setDocument(String path, Map<String, dynamic> data, {bool merge = false}) async {
    try {
      return await _firestore.doc(path).set(data, SetOptions(merge: merge));
    } catch (e) {
      throw FirebaseServiceException('Failed to set document at $path', e);
    }
  }

  /// Update a document.
  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    try {
      return await _firestore.doc(path).update(data);
    } catch (e) {
      throw FirebaseServiceException('Failed to update document at $path', e);
    }
  }

  /// Delete a document.
  Future<void> deleteDocument(String path) async {
    try {
      return await _firestore.doc(path).delete();
    } catch (e) {
      throw FirebaseServiceException('Failed to delete document at $path', e);
    }
  }

  /// Get a document by path.
  Future<DocumentSnapshot> getDocument(String path) async {
    try {
      return await _firestore.doc(path).get();
    } catch (e) {
      throw FirebaseServiceException('Failed to get document at $path', e);
    }
  }

  /// Get documents from a collection.
  Future<QuerySnapshot> getCollection(String path, {
    List<Query Function(Query)> queryModifiers = const [],
  }) async {
    try {
      Query query = _firestore.collection(path);
      
      // Apply any query modifiers (where, orderBy, limit, etc.)
      for (final modifier in queryModifiers) {
        query = modifier(query);
      }
      
      return await query.get();
    } catch (e) {
      throw FirebaseServiceException('Failed to get collection at $path', e);
    }
  }

  /// Stream of documents from a collection.
  Stream<QuerySnapshot> streamCollection(String path, {
    List<Query Function(Query)> queryModifiers = const [],
  }) {
    try {
      Query query = _firestore.collection(path);
      
      // Apply any query modifiers
      for (final modifier in queryModifiers) {
        query = modifier(query);
      }
      
      return query.snapshots();
    } catch (e) {
      throw FirebaseServiceException('Failed to stream collection at $path', e);
    }
  }

  /// Stream of a document.
  Stream<DocumentSnapshot> streamDocument(String path) {
    try {
      return _firestore.doc(path).snapshots();
    } catch (e) {
      throw FirebaseServiceException('Failed to stream document at $path', e);
    }
  }
  
  /// Generate a new document ID for a collection
  String generateId(String collectionPath) {
    return _firestore.collection(collectionPath).doc().id;
  }
  
  /// Check if a document exists
  Future<bool> documentExists(String path) async {
    try {
      final doc = await _firestore.doc(path).get();
      return doc.exists;
    } catch (e) {
      throw FirebaseServiceException('Failed to check if document exists at $path', e);
    }
  }
  
  /// Run a transaction
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transactionHandler) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e) {
      throw FirebaseServiceException('Transaction failed', e);
    }
  }
  
  /// Create a batch write
  WriteBatch batch() {
    return _firestore.batch();
  }
} 