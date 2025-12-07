// ========================================
// FILE: assignment_tracker_repository.dart
// PURPOSE: Repository for Assignment Tracking System
// DESCRIPTION: CRUD operations for assignment_trackers collection
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/assignment_tracker_model.dart';

class AssignmentTrackerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get collection reference
  CollectionReference get _trackersCollection =>
      _firestore.collection('assignment_trackers');

  // ========================================
  // QUERY METHODS
  // ========================================

  /// Get all trackers for a specific assignment (Real-time Stream)
  /// Used in Grade Table when instructor selects an assignment
  Stream<List<AssignmentTrackerModel>> streamTrackersForAssignment(
    String assignmentId, {
    String? groupId,
    TrackerStatus? status,
    String? searchQuery,
  }) {
    Query query = _trackersCollection
        .where('assignmentId', isEqualTo: assignmentId)
        .orderBy('studentName'); // Sort by name

    // Apply filters
    if (groupId != null && groupId.isNotEmpty) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      var trackers = snapshot.docs
          .map((doc) => AssignmentTrackerModel.fromFirestore(doc))
          .toList();

      // Apply search filter client-side (Firestore doesn't support full-text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        trackers = trackers.where((tracker) {
          return tracker.studentName.toLowerCase().contains(lowerQuery) ||
              tracker.studentEmail.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return trackers;
    });
  }

  /// Get trackers for multiple assignments (for overview/stats)
  Stream<List<AssignmentTrackerModel>> streamTrackersForCourse(
    String courseId, {
    String? groupId,
    TrackerStatus? status,
  }) {
    Query query = _trackersCollection.where('courseId', isEqualTo: courseId);

    if (groupId != null && groupId.isNotEmpty) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AssignmentTrackerModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get single tracker by ID
  Future<AssignmentTrackerModel?> getTrackerById(String trackerId) async {
    try {
      final doc = await _trackersCollection.doc(trackerId).get();
      if (doc.exists) {
        return AssignmentTrackerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting tracker: $e');
      return null;
    }
  }

  /// Get tracker for specific student + assignment
  Future<AssignmentTrackerModel?> getTrackerForStudent(
    String assignmentId,
    String studentId,
  ) async {
    final trackerId =
        AssignmentTrackerModel.getTrackerId(assignmentId, studentId);
    return getTrackerById(trackerId);
  }

  /// Get all trackers for a specific student in a course (Real-time Stream)
  /// Used to filter assignments that student has access to
  Stream<List<AssignmentTrackerModel>> streamTrackersForStudent(
    String studentId, {
    String? courseId,
  }) {
    Query query = _trackersCollection.where('studentId', isEqualTo: studentId);

    if (courseId != null && courseId.isNotEmpty) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AssignmentTrackerModel.fromFirestore(doc))
          .toList();
    });
  }

  // ========================================
  // UPDATE METHODS
  // ========================================

  /// Update grade for a tracker (Instructor chấm điểm)
  /// This will trigger Cloud Function to sync grade back to submission
  Future<void> updateGrade({
    required String trackerId,
    required double grade,
    String? feedback,
    required String gradedBy,
  }) async {
    try {
      await _trackersCollection.doc(trackerId).update({
        'grade': grade,
        'feedback': feedback,
        'status': TrackerStatus.graded.name,
        'gradedBy': gradedBy,
        'gradedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Updated grade for tracker: $trackerId');
    } catch (e) {
      print('❌ Error updating grade: $e');
      rethrow;
    }
  }

  /// Batch update grades for multiple students
  Future<void> batchUpdateGrades(
    List<Map<String, dynamic>> gradeUpdates,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final update in gradeUpdates) {
        final trackerId = update['trackerId'] as String;
        final grade = update['grade'] as double;
        final feedback = update['feedback'] as String?;
        final gradedBy = update['gradedBy'] as String;

        batch.update(_trackersCollection.doc(trackerId), {
          'grade': grade,
          'feedback': feedback,
          'status': TrackerStatus.graded.name,
          'gradedBy': gradedBy,
          'gradedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Batch updated ${gradeUpdates.length} grades');
    } catch (e) {
      print('❌ Error batch updating grades: $e');
      rethrow;
    }
  }

  /// Update tracker status manually (if needed)
  Future<void> updateStatus({
    required String trackerId,
    required TrackerStatus status,
  }) async {
    try {
      await _trackersCollection.doc(trackerId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Updated status for tracker: $trackerId');
    } catch (e) {
      print('❌ Error updating status: $e');
      rethrow;
    }
  }

  // ========================================
  // STATISTICS METHODS
  // ========================================

  /// Get statistics for an assignment
  Future<Map<String, int>> getAssignmentStats(String assignmentId) async {
    try {
      final snapshot = await _trackersCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      int totalStudents = snapshot.docs.length;
      int submitted = 0;
      int late = 0;
      int missing = 0;
      int graded = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String;
        switch (status) {
          case 'submitted':
            submitted++;
            break;
          case 'late':
            late++;
            break;
          case 'missing':
            missing++;
            break;
          case 'graded':
            graded++;
            break;
        }
      }

      return {
        'total': totalStudents,
        'submitted': submitted,
        'late': late,
        'missing': missing,
        'graded': graded,
      };
    } catch (e) {
      print('❌ Error getting assignment stats: $e');
      return {
        'total': 0,
        'submitted': 0,
        'late': 0,
        'missing': 0,
        'graded': 0,
      };
    }
  }

  /// Get average grade for assignment
  Future<double?> getAverageGrade(String assignmentId) async {
    try {
      final snapshot = await _trackersCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .where('grade', isNotEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) return null;

      double sum = 0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final grade = data['grade'];
        if (grade != null) {
          sum += (grade as num).toDouble();
          count++;
        }
      }

      return count > 0 ? sum / count : null;
    } catch (e) {
      print('❌ Error getting average grade: $e');
      return null;
    }
  }

  // ========================================
  // DELETE METHODS
  // ========================================

  /// Delete tracker (usually when assignment is deleted)
  Future<void> deleteTracker(String trackerId) async {
    try {
      await _trackersCollection.doc(trackerId).delete();
      print('✅ Deleted tracker: $trackerId');
    } catch (e) {
      print('❌ Error deleting tracker: $e');
      rethrow;
    }
  }

  /// Delete all trackers for an assignment
  Future<void> deleteTrackersForAssignment(String assignmentId) async {
    try {
      final snapshot = await _trackersCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Deleted ${snapshot.docs.length} trackers for assignment');
    } catch (e) {
      print('❌ Error deleting trackers: $e');
      rethrow;
    }
  }

  // ========================================
  // EXPORT METHODS
  // ========================================

  /// Get trackers for CSV export (with all fields)
  Future<List<AssignmentTrackerModel>> getTrackersForExport(
    String assignmentId, {
    String? groupId,
  }) async {
    try {
      Query query = _trackersCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('studentName');

      if (groupId != null && groupId.isNotEmpty) {
        query = query.where('groupId', isEqualTo: groupId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AssignmentTrackerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting trackers for export: $e');
      return [];
    }
  }
}
