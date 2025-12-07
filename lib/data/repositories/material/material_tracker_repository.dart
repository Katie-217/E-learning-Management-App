// ========================================
// FILE: material_tracker_repository.dart
// MÔ TẢ: Repository cho Material Tracking System
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/material_tracker_model.dart';

class MaterialTrackerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _trackersCollection =>
      _firestore.collection('material_trackers');

  // ========================================
  // QUERY METHODS
  // ========================================

  /// Stream all trackers for a material (Real-time)
  /// Support Group Filter
  Stream<List<MaterialTrackerModel>> streamTrackersForMaterial(
    String materialId, {
    String? groupId, // ✅ Filter theo nhóm
    String? status, // 'new', 'viewed', 'downloaded'
  }) {
    Query query =
        _trackersCollection.where('materialId', isEqualTo: materialId);

    // Apply Group Filter
    if (groupId != null && groupId.isNotEmpty && groupId != 'All') {
      query = query.where('groupId', isEqualTo: groupId);
    }

    // Apply Status Filter
    if (status != null && status.isNotEmpty && status != 'All') {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MaterialTrackerModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get tracker for specific student
  Future<MaterialTrackerModel?> getTrackerForStudent(
    String materialId,
    String studentId,
  ) async {
    try {
      final trackerId = MaterialTrackerModel.generateId(materialId, studentId);
      final doc = await _trackersCollection.doc(trackerId).get();

      if (doc.exists) {
        return MaterialTrackerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting tracker: $e');
      return null;
    }
  }

  // ========================================
  // UPDATE METHODS (Called by Student)
  // ========================================

  /// Mark material as viewed by student
  Future<void> markAsViewed(String materialId, String studentId) async {
    try {
      final trackerId = MaterialTrackerModel.generateId(materialId, studentId);
      final docRef = _trackersCollection.doc(trackerId);

      // ✅ Use set() with merge to create if not exists
      await docRef.set({
        'materialId': materialId,
        'studentId': studentId,
        'isViewed': true,
        'viewedAt': DateTime.now().toIso8601String(),
        'status': 'viewed',
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)); // ✅ Merge = true để giữ các field khác

      print('✅ Marked as viewed: $trackerId');
    } catch (e) {
      print('❌ Error marking as viewed: $e');
      rethrow;
    }
  }

  /// Mark material as downloaded by student
  Future<void> markAsDownloaded(String materialId, String studentId) async {
    try {
      final trackerId = MaterialTrackerModel.generateId(materialId, studentId);
      final docRef = _trackersCollection.doc(trackerId);

      // ✅ Use set() with merge to create if not exists
      await docRef.set({
        'materialId': materialId,
        'studentId': studentId,
        'isDownloaded': true,
        'downloadedAt': DateTime.now().toIso8601String(),
        'status': 'downloaded',
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true)); // ✅ Merge = true để giữ các field khác

      print('✅ Marked as downloaded: $trackerId');
    } catch (e) {
      print('❌ Error marking as downloaded: $e');
      rethrow;
    }
  }

  // ========================================
  // STATISTICS METHODS
  // ========================================

  /// Get statistics for material
  Future<Map<String, int>> getMaterialStats(String materialId) async {
    try {
      final snapshot = await _trackersCollection
          .where('materialId', isEqualTo: materialId)
          .get();

      int totalStudents = snapshot.docs.length;
      int viewedCount = 0;
      int downloadedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isViewed'] == true) viewedCount++;
        if (data['isDownloaded'] == true) downloadedCount++;
      }

      return {
        'total': totalStudents,
        'viewed': viewedCount,
        'notViewed': totalStudents - viewedCount,
        'downloaded': downloadedCount,
      };
    } catch (e) {
      print('❌ Error getting material stats: $e');
      return {
        'total': 0,
        'viewed': 0,
        'notViewed': 0,
        'downloaded': 0,
      };
    }
  }

  // ========================================
  // DELETE METHODS
  // ========================================

  /// Delete all trackers for a material
  Future<void> deleteTrackersForMaterial(String materialId) async {
    try {
      final snapshot = await _trackersCollection
          .where('materialId', isEqualTo: materialId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print(
          '✅ Deleted ${snapshot.docs.length} trackers for material: $materialId');
    } catch (e) {
      print('❌ Error deleting trackers: $e');
      rethrow;
    }
  }
}
