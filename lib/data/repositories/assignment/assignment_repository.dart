// ========================================
// FILE: assignment_repository.dart
// MÔ TẢ: Repository cho Assignment - Sub-collection trong course_of_study
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/assignment_model.dart';

class AssignmentRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _courseCollectionName = 'course_of_study';
  static const String _assignmentSubCollectionName = 'assignments';

  // ========================================
  // HÀM: getAssignmentsByCourse
  // MÔ TẢ: Lấy assignments từ sub-collection trong course_of_study
  // ========================================
  static Future<List<Assignment>> getAssignmentsByCourse(
      String courseId) async {
    try {
      print('DEBUG: Fetching assignments for course: $courseId');

      final QuerySnapshot snapshot = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_assignmentSubCollectionName)
          .orderBy('deadline', descending: false)
          .get();

      print('DEBUG: Found ${snapshot.docs.length} assignments');

      return snapshot.docs.map((doc) => Assignment.fromFirestore(doc)).toList();
    } catch (e) {
      print('DEBUG: Error fetching assignments: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getAllAssignmentsForUser
  // MÔ TẢ: Lấy tất cả assignments của user từ các course đã enroll
  // ========================================
  static Future<List<Assignment>> getAllAssignmentsForUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in for assignments');
        return [];
      }

      // Lấy danh sách courses mà user đã enroll
      final userCoursesSnapshot = await _firestore
          .collection(_courseCollectionName)
          .where('students', arrayContains: user.uid)
          .get();

      List<Assignment> allAssignments = [];

      for (var courseDoc in userCoursesSnapshot.docs) {
        final courseAssignments = await getAssignmentsByCourse(courseDoc.id);
        allAssignments.addAll(courseAssignments);
      }

      // Sort by deadline
      allAssignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      print('DEBUG: Total assignments for user: ${allAssignments.length}');
      return allAssignments;
    } catch (e) {
      print('DEBUG: Error fetching user assignments: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getAssignmentById
  // MÔ TẢ: Lấy assignment cụ thể từ course và assignment ID
  // ========================================
  static Future<Assignment?> getAssignmentById(
      String courseId, String assignmentId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_assignmentSubCollectionName)
          .doc(assignmentId)
          .get();

      if (doc.exists) {
        return Assignment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('DEBUG: Error fetching assignment by ID: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: createAssignment
  // MÔ TẢ: Tạo assignment mới trong course (chỉ cho instructor)
  // ========================================
  static Future<bool> createAssignment(
      String courseId, Assignment assignment) async {
    try {
      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_assignmentSubCollectionName)
          .add(assignment.toFirestore());

      print('DEBUG: Assignment created successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error creating assignment: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: updateAssignment
  // MÔ TẢ: Cập nhật assignment (chỉ cho instructor)
  // ========================================
  static Future<bool> updateAssignment(
      String courseId, String assignmentId, Assignment assignment) async {
    try {
      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_assignmentSubCollectionName)
          .doc(assignmentId)
          .update(assignment.toFirestore());

      print('DEBUG: Assignment updated successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error updating assignment: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: deleteAssignment
  // MÔ TẢ: Xóa assignment (chỉ cho instructor)
  // ========================================
  static Future<bool> deleteAssignment(
      String courseId, String assignmentId) async {
    try {
      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_assignmentSubCollectionName)
          .doc(assignmentId)
          .delete();

      print('DEBUG: Assignment deleted successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error deleting assignment: $e');
      return false;
    }
  }
}
