import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class to handle all Firebase Firestore operations.
class FirebaseService {
  /// The Firestore instance.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a collection reference.
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference.
  DocumentReference document(String path) {
    return _firestore.doc(path);
  }

  /// Add a document to a collection.
  Future<DocumentReference> addDocument(String collection, Map<String, dynamic> data) {
    return _firestore.collection(collection).add(data);
  }

  /// Set a document in a collection with a specific ID.
  Future<void> setDocument(String path, Map<String, dynamic> data) {
    return _firestore.doc(path).set(data);
  }

  /// Update a document.
  Future<void> updateDocument(String path, Map<String, dynamic> data) {
    return _firestore.doc(path).update(data);
  }

  /// Delete a document.
  Future<void> deleteDocument(String path) {
    return _firestore.doc(path).delete();
  }

  /// Get a document by path.
  Future<DocumentSnapshot> getDocument(String path) {
    return _firestore.doc(path).get();
  }

  /// Get documents from a collection.
  Future<QuerySnapshot> getCollection(String path) {
    return _firestore.collection(path).get();
  }

  /// Stream of documents from a collection.
  Stream<QuerySnapshot> streamCollection(String path) {
    return _firestore.collection(path).snapshots();
  }

  /// Stream of a document.
  Stream<DocumentSnapshot> streamDocument(String path) {
    return _firestore.doc(path).snapshots();
  }
} 