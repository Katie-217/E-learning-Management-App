// import 'package:cloud_firestore/cloud_firestore.dart';

/// FirestoreService
/// -------------------------------------------------------------------------
/// ✅ Phiên bản clean, hợp nhất từ 2 file cũ:
/// - firestore_service.dart
/// - firestore_services.dart
///
/// ⚙️ Tạm thời giữ mock data để kiểm tra UI (không cần Firebase).
/// 🔥 Khi sẵn sàng kết nối Firestore thật, chỉ cần bỏ comment ở phần “Firebase Real”
/// -------------------------------------------------------------------------
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService _instance = FirestoreService._internal();
  static FirestoreService get instance => _instance;

  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // 🔥 Firebase Real

  /// 🧩 MOCK DATA (UI Test)
  /// -------------------------------------------------------------------------
  /// Dùng tạm khi bạn chưa bật Firestore.
  final Map<String, List<Map<String, dynamic>>> _mockCollections = {
    "assignments": [
      {
        "id": "A1",
        "title": "Project 1: Portfolio Website",
        "dueDate": "Oct 15, 2025",
        "points": 100,
        "status": "pending",
        "student": "Student A",
      },
      {
        "id": "A2",
        "title": "Assignment 2: JavaScript DOM",
        "dueDate": "Oct 20, 2025",
        "points": 50,
        "status": "submitted",
        "student": "Student B",
      },
    ],
    "quizzes": [
      {
        "id": "Q1",
        "title": "Quiz 1: HTML & CSS",
        "score": 18,
        "max": 20,
        "status": "graded",
      },
      {
        "id": "Q2",
        "title": "Quiz 2: JavaScript Basics",
        "score": null,
        "max": 20,
        "status": "pending",
      },
    ],
    "announcements": [
      {
        "id": "AN1",
        "title": "Welcome to Web Programming",
        "author": "Dr. Nguyen Van A",
        "date": "Oct 5, 2025",
        "content":
            "Welcome everyone! Please review the syllabus and complete the first assignment by next week.",
      },
    ]
  };

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simulate delay
    return _mockCollections[collectionPath] ?? [];
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCollections[collectionPath]
        ?.firstWhere((item) => item["id"] == docId, orElse: () => {});
  }

  Future<void> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockCollections[collectionPath]?.add(data);
  }

  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final collection = _mockCollections[collectionPath];
    if (collection != null) {
      final index = collection.indexWhere((item) => item["id"] == docId);
      if (index != -1) collection[index] = {...collection[index], ...data};
    }
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockCollections[collectionPath]
        ?.removeWhere((item) => item["id"] == docId);
  }

  // -------------------------------------------------------------------------
  // 🔥 FIREBASE REAL IMPLEMENTATIONS (COMMENTED)
  // -------------------------------------------------------------------------
  /*
  Future<DocumentReference?> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collectionPath).add(data);
      return docRef;
    } catch (e) {
      print('❌ FirestoreService.addDocument error: $e');
      return null;
    }
  }

  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set(data, SetOptions(merge: merge));
    } catch (e) {
      print('❌ FirestoreService.setDocument error: $e');
    }
  }

  Future<DocumentSnapshot?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      return await _firestore.collection(collectionPath).doc(docId).get();
    } catch (e) {
      print('❌ FirestoreService.getDocument error: $e');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot>> getCollection({
    required String collectionPath,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore.collection(collectionPath);
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      print('❌ FirestoreService.getCollection error: $e');
      return [];
    }
  }

  Stream<List<QueryDocumentSnapshot>> streamCollection({
    required String collectionPath,
    String? orderBy,
    bool descending = false,
    Map<String, dynamic>? whereConditions,
  }) {
    Query query = _firestore.collection(collectionPath);

    if (whereConditions != null) {
      whereConditions.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      print('❌ FirestoreService.updateDocument error: $e');
    }
  }

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print('❌ FirestoreService.deleteDocument error: $e');
    }
  }
  */
}
