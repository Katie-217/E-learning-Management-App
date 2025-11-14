// ========================================
// FILE: submission_repository.dart
// MÔ TẢ: Repository cho Submission - Sub-collection trong course_of_study
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/submission_model.dart';

class SubmissionRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _courseCollectionName = 'course_of_study';
  static const String _submissionSubCollectionName = 'submissions';

  // ========================================
  // HÀM: getSubmissionsByCourse
  // MÔ TẢ: Lấy submissions từ sub-collection trong course_of_study
  // ========================================
  static Future<List<SubmissionModel>> getSubmissionsByCourse(
      String courseId) async {
    try {
      print('DEBUG: Fetching submissions for course: $courseId');

      final QuerySnapshot snapshot = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_submissionSubCollectionName)
          .orderBy('submittedAt', descending: true)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} submissions');

      return snapshot.docs
          .map((doc) => SubmissionModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching submissions: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getSubmissionsByAssignment
  // MÔ TẢ: Lấy submissions của một assignment cụ thể
  // ========================================
  static Future<List<SubmissionModel>> getSubmissionsByAssignment(
      String courseId, String assignmentId) async {
    try {
      print('DEBUG: Fetching submissions for assignment: $assignmentId');

      final QuerySnapshot snapshot = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_submissionSubCollectionName)
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('submittedAt', descending: true)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} submissions for assignment');

      return snapshot.docs
          .map((doc) => SubmissionModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching submissions by assignment: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getUserSubmissions
  // MÔ TẢ: Lấy tất cả submissions của user hiện tại
  // ========================================
  static Future<List<SubmissionModel>> getUserSubmissions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in for submissions');
        return [];
      }

      // Lấy danh sách courses mà user đã enroll
      final userCoursesSnapshot = await _firestore
          .collection(_courseCollectionName)
          .where('students', arrayContains: user.uid)
          .get();

      List<SubmissionModel> allSubmissions = [];

      for (var courseDoc in userCoursesSnapshot.docs) {
        final submissionsSnapshot = await _firestore
            .collection(_courseCollectionName)
            .doc(courseDoc.id)
            .collection(_submissionSubCollectionName)
            .where('studentId', isEqualTo: user.uid)
            .get();

        final courseSubmissions = submissionsSnapshot.docs
            .map((doc) => SubmissionModel.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList();

        allSubmissions.addAll(courseSubmissions);
      }

      // Sort by submission date
      allSubmissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      print('DEBUG: Total submissions for user: ${allSubmissions.length}');
      return allSubmissions;
    } catch (e) {
      print('DEBUG: Error fetching user submissions: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: submitAssignment
  // MÔ TẢ: Submit assignment bài làm
  // ========================================
  static Future<bool> submitAssignment(
      String courseId, SubmissionModel submission) async {
    try {
      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_submissionSubCollectionName)
          .add(submission.toMap());

      print('DEBUG: Assignment submitted successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error submitting assignment: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: updateSubmission
  // MÔ TẢ: Cập nhật submission (resubmit hoặc grade)
  // ========================================
  static Future<bool> updateSubmission(
      String courseId, String submissionId, SubmissionModel submission) async {
    try {
      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_submissionSubCollectionName)
          .doc(submissionId)
          .update(submission.toMap());

      print('DEBUG: Submission updated successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error updating submission: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: getSubmissionById
  // MÔ TẢ: Lấy submission cụ thể
  // ========================================
  static Future<SubmissionModel?> getSubmissionById(
      String courseId, String submissionId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_submissionSubCollectionName)
          .doc(submissionId)
          .get();

      if (doc.exists) {
        return SubmissionModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('DEBUG: Error fetching submission by ID: $e');
      return null;
    }
  }
}
