// ========================================
// FILE: quiz_tracker_repository.dart
// PURPOSE: Repository for Quiz Tracker CRUD operations
// DESCRIPTION: Real-time tracking for quiz progress and scores
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearning_management_app/domain/models/quiz_tracker_model.dart';

class QuizTrackerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream trackers for a specific quiz
  Stream<List<QuizTrackerModel>> streamTrackersForQuiz(
    String quizId, {
    String? groupId,
    String? status,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('quiz_trackers')
        .where('quizId', isEqualTo: quizId);

    if (groupId != null && groupId.isNotEmpty) {
      query = query.where('groupId', isEqualTo: groupId);
    }

    if (status != null && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('studentName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return QuizTrackerModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Get single tracker
  Future<QuizTrackerModel?> getTracker(String quizId, String studentId) async {
    final compositeId = '${quizId}_$studentId';
    final doc =
        await _firestore.collection('quiz_trackers').doc(compositeId).get();

    if (!doc.exists) return null;

    return QuizTrackerModel.fromMap({
      'id': doc.id,
      ...doc.data()!,
    });
  }

  /// Update tracker status (called by Cloud Function)
  Future<void> updateTracker(
    String quizId,
    String studentId, {
    String? status,
    int? attemptCount,
    double? score,
    DateTime? startedAt,
    DateTime? lastAttemptAt,
    DateTime? completedAt,
    String? lastSubmissionId,
  }) async {
    final compositeId = '${quizId}_$studentId';

    final updates = <String, dynamic>{};
    if (status != null) updates['status'] = status;
    if (attemptCount != null) updates['attemptCount'] = attemptCount;
    if (score != null) updates['score'] = score;
    if (startedAt != null) {
      updates['startedAt'] = Timestamp.fromDate(startedAt);
    }
    if (lastAttemptAt != null) {
      updates['lastAttemptAt'] = Timestamp.fromDate(lastAttemptAt);
    }
    if (completedAt != null) {
      updates['completedAt'] = Timestamp.fromDate(completedAt);
    }
    if (lastSubmissionId != null) {
      updates['lastSubmissionId'] = lastSubmissionId;
    }

    await _firestore.collection('quiz_trackers').doc(compositeId).update(
          updates,
        );
  }

  /// Manually update grade (instructor override)
  Future<void> updateGrade(
    String quizId,
    String studentId,
    double newScore,
  ) async {
    final compositeId = '${quizId}_$studentId';

    await _firestore.collection('quiz_trackers').doc(compositeId).update({
      'score': newScore,
    });
  }

  /// Delete tracker (when quiz or student removed)
  Future<void> deleteTracker(String quizId, String studentId) async {
    final compositeId = '${quizId}_$studentId';
    await _firestore.collection('quiz_trackers').doc(compositeId).delete();
  }

  /// Get all trackers for a student across all quizzes in a course
  Future<List<QuizTrackerModel>> getStudentTrackers(
    String courseId,
    String studentId,
  ) async {
    final snapshot = await _firestore
        .collection('quiz_trackers')
        .where('courseId', isEqualTo: courseId)
        .where('studentId', isEqualTo: studentId)
        .get();

    return snapshot.docs.map((doc) {
      return QuizTrackerModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      });
    }).toList();
  }
}
