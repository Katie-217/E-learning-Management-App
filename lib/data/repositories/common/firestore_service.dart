import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
  }) async {
    final snapshot = await _firestore.collection(collectionPath).get();
    return snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    final doc =
        await _firestore.collection(collectionPath).doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    return {...doc.data()!, 'id': doc.id};
  }

  Future<void> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collectionPath).add(data);
  }

  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await _firestore
        .collection(collectionPath)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection(collectionPath)
        .doc(docId)
        .update(data);
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    await _firestore.collection(collectionPath).doc(docId).delete();
  }

  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)?
        queryBuilder,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Stream<Map<String, dynamic>?> documentStream({
    required String collectionPath,
    required String docId,
  }) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .snapshots()
        .map(
          (doc) => doc.exists && doc.data() != null
              ? {...doc.data()!, 'id': doc.id}
              : null,
        );
  }
}
{
  "cells": [],
  "metadata": {
    "language_info": {
      "name": "python"
    }
  },
  "nbformat": 4,
  "nbformat_minor": 2
}