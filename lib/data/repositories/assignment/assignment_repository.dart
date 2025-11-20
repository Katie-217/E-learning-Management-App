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
      print('DEBUG: ========== FETCHING ASSIGNMENTS ==========');
      print('DEBUG: 🔍 Fetching assignments for course: $courseId');
      print('DEBUG: 📂 Primary path: $_assignmentSubCollectionName (root)');

      QuerySnapshot<Map<String, dynamic>>? snapshot;
      bool usedRootCollection = false;

      // 1. Try new root-level `assignments` collection
      try {
        snapshot = await _firestore
            .collection(_assignmentSubCollectionName)
            .where('courseId', isEqualTo: courseId)
            .orderBy('deadline', descending: false)
            .get();
        usedRootCollection = true;
        print(
            'DEBUG: ✅ Root collection query succeeded with ${snapshot.docs.length} docs');
      } catch (e) {
        print(
            'DEBUG: ⚠️ Root collection query with orderBy failed: $e — retrying without orderBy');
        try {
          snapshot = await _firestore
              .collection(_assignmentSubCollectionName)
              .where('courseId', isEqualTo: courseId)
              .get();
          usedRootCollection = true;
        } catch (e2) {
          print('DEBUG: ❌ Root collection query failed: $e2');
          snapshot = null;
        }
      }

      // 2. Fallback to legacy sub-collection path inside course document
      if (snapshot == null || snapshot.docs.isEmpty) {
        print(
            'DEBUG: ⚠️ Root collection returned no documents, trying legacy course path...');
        try {
          snapshot = await _firestore
              .collection(_courseCollectionName)
              .doc(courseId)
              .collection(_assignmentSubCollectionName)
              .orderBy('deadline', descending: false)
              .get();
          usedRootCollection = false;
        } catch (e) {
          print(
              'DEBUG: ⚠️ Legacy path query with orderBy failed: $e — retrying without orderBy');
          snapshot = await _firestore
              .collection(_courseCollectionName)
              .doc(courseId)
              .collection(_assignmentSubCollectionName)
              .get();
          usedRootCollection = false;
        }
      }

      // 3. Final fallback: collectionGroup query (covers nested structures)
      if (snapshot == null || snapshot.docs.isEmpty) {
        print(
            'DEBUG: ⚠️ Legacy path also empty. Trying collectionGroup fallback...');
        try {
          snapshot = await _firestore
              .collectionGroup(_assignmentSubCollectionName)
              .where('courseId', isEqualTo: courseId)
              .get();
        } catch (e) {
          print('DEBUG: ❌ CollectionGroup fallback failed: $e');
        }
      }

      final docs = snapshot?.docs ?? [];
      print('DEBUG: 📋 Found ${docs.length} assignment documents');

      if (docs.isEmpty) {
        print('DEBUG: ⚠️ No assignments found in sub-collection');
        print(
            'DEBUG: 💡 Checked paths -> root: $usedRootCollection, legacy: ${!usedRootCollection}');
        return [];
      }

      // Parse assignments
      final assignments = <Assignment>[];
      for (var doc in docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
          print(
              'DEBUG: ✅ Parsed assignment: ${assignment.title} (ID: ${assignment.id})');
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment doc ${doc.id}: $e');
        }
      }

      // Sort by deadline if not already sorted
      assignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      print('DEBUG: ✅ Successfully loaded ${assignments.length} assignments');
      print('DEBUG: ===========================================');
      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignments: $e');
      print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
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
      // Try root-level assignment document first (new storage)
      DocumentSnapshot doc = await _firestore
          .collection(_assignmentSubCollectionName)
          .doc(assignmentId)
          .get();

      if (!doc.exists) {
        // Fallback to legacy course sub-collection path
        doc = await _firestore
            .collection(_courseCollectionName)
            .doc(courseId)
            .collection(_assignmentSubCollectionName)
            .doc(assignmentId)
            .get();
      }

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
  // UPDATED: Đảm bảo courseId được set cho Collection Group Query
  // ========================================
  static Future<bool> createAssignment(
      String courseId, Assignment assignment) async {
    try {
      // ✅ CRITICAL: Ensure assignment has courseId for Collection Group Query
      final assignmentWithCourseId = assignment.copyWith(courseId: courseId);

      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_assignmentSubCollectionName)
          .add(assignmentWithCourseId.toFirestore());

      print('DEBUG: ✅ Assignment created with courseId: $courseId');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Error creating assignment: $e');
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

  // ========================================
  // COLLECTION GROUP QUERY METHODS - NEW FEATURE
  // Sử dụng courseId để query cross-course assignments
  // ========================================

  // ========================================
  // HÀM: getAllAssignmentsAcrossSystem
  // MÔ TẢ: Lấy TẤT CẢ assignments trong toàn hệ thống (Collection Group Query)
  // USE CASE: Admin xuất CSV tất cả assignments, system analytics
  // ========================================
  static Future<List<Assignment>> getAllAssignmentsAcrossSystem() async {
    try {
      print(
          'DEBUG: 🌐 Fetching ALL assignments across system using Collection Group Query');

      final QuerySnapshot snapshot = await _firestore
          .collectionGroup(_assignmentSubCollectionName)
          .orderBy('deadline', descending: false)
          .get();

      print(
          'DEBUG: 📊 Found ${snapshot.docs.length} assignments across all courses');

      final assignments = <Assignment>[];
      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
          print(
              'DEBUG: ✅ Assignment: ${assignment.title} (Course: ${assignment.courseId})');
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment: $e');
        }
      }

      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error in Collection Group Query: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getUpcomingAssignmentsForStudent
  // MÔ TẢ: Lấy TẤT CẢ bài tập sắp hết hạn của sinh viên (từ MỌI khóa học)
  // USE CASE: Student dashboard - "All assignments due soon"
  // ========================================
  static Future<List<Assignment>> getUpcomingAssignmentsForStudent({
    required List<String> enrolledCourseIds,
    required int daysAhead,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime futureDate = now.add(Duration(days: daysAhead));

      print('DEBUG: 📅 Fetching upcoming assignments (next $daysAhead days)');
      print('DEBUG: 📚 From courses: ${enrolledCourseIds.join(", ")}');

      final QuerySnapshot snapshot = await _firestore
          .collectionGroup(_assignmentSubCollectionName)
          .where('courseId',
              whereIn: enrolledCourseIds) // ✅ Filter by enrolled courses
          .where('deadline', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('deadline',
              isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
          .orderBy('deadline', descending: false)
          .get();

      print('DEBUG: 🎯 Found ${snapshot.docs.length} upcoming assignments');

      final assignments = <Assignment>[];
      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
          print(
              'DEBUG: ⏰ Upcoming: ${assignment.title} - Due: ${assignment.deadline} (Course: ${assignment.courseId})');
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment: $e');
        }
      }

      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error fetching upcoming assignments: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getAssignmentsByMultipleCourses
  // MÔ TẢ: Lấy assignments từ nhiều courses cùng lúc
  // USE CASE: Cross-course analytics, bulk operations
  // ========================================
  static Future<Map<String, List<Assignment>>> getAssignmentsByMultipleCourses(
      List<String> courseIds) async {
    try {
      print(
          'DEBUG: 📋 Fetching assignments from multiple courses: ${courseIds.join(", ")}');

      final QuerySnapshot snapshot = await _firestore
          .collectionGroup(_assignmentSubCollectionName)
          .where('courseId', whereIn: courseIds)
          .get();

      print(
          'DEBUG: 📊 Found ${snapshot.docs.length} assignments from ${courseIds.length} courses');

      // Group assignments by courseId
      final Map<String, List<Assignment>> assignmentsByCourse = {};

      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          final courseId = assignment.courseId;

          if (!assignmentsByCourse.containsKey(courseId)) {
            assignmentsByCourse[courseId] = [];
          }
          assignmentsByCourse[courseId]!.add(assignment);
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment: $e');
        }
      }

      // Sort assignments within each course by deadline
      for (var courseId in assignmentsByCourse.keys) {
        assignmentsByCourse[courseId]!
            .sort((a, b) => a.deadline.compareTo(b.deadline));
        print(
            'DEBUG: ✅ Course $courseId: ${assignmentsByCourse[courseId]!.length} assignments');
      }

      return assignmentsByCourse;
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignments by multiple courses: $e');
      return {};
    }
  }
}
