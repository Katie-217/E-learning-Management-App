// ========================================
// FILE: assignment_repository.dart
// MÔ TẢ: Repository cho Assignment - Root Collection
// REFACTORED: Di chuyển từ Sub-collection sang Root Collection
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/assignment_model.dart';

class AssignmentRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ✅ NEW: Root Collection instead of Sub-collection
  static const String _assignmentCollectionName = 'assignments';

  // ========================================
  // HÀM: getAssignmentsByCourse
  // MÔ TẢ: Lấy assignments từ Root Collection với where filter
  // ========================================
  static Future<List<Assignment>> getAssignmentsByCourse(
      String courseId) async {
    try {
      print('DEBUG: ========== FETCHING ASSIGNMENTS ==========');
      print('DEBUG: 🔍 Fetching assignments for course: $courseId');
      print('DEBUG: 📂 Root Collection: $_assignmentCollectionName');

      QuerySnapshot snapshot;
      try {
        // ✅ NEW: Root Collection with where filter - sort by createdAt descending (newest first)
        snapshot = await _firestore
            .collection(_assignmentCollectionName)
            .where('courseId', isEqualTo: courseId)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // Nếu orderBy fail (có thể do thiếu index), thử query không orderBy
        print('DEBUG: ⚠️ Query with orderBy failed: $e');
        print('DEBUG: 💡 Trying without orderBy...');
        snapshot = await _firestore
            .collection(_assignmentCollectionName)
            .where('courseId', isEqualTo: courseId)
            .get();
      }

      print('DEBUG: 📋 Found ${snapshot.docs.length} assignment documents');

      if (snapshot.docs.isEmpty) {
        print('DEBUG: ⚠️ No assignments found for courseId: $courseId');
        return [];
      }

      // Parse assignments
      final assignments = <Assignment>[];
      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
          print(
              'DEBUG: ✅ Parsed assignment: ${assignment.title} (ID: ${assignment.id})');
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment doc ${doc.id}: $e');
        }
      }

      // Sort by createdAt descending (newest first) if not already sorted
      assignments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('DEBUG: ✅ Successfully loaded ${assignments.length} assignments');
      print('DEBUG: ===========================================');
      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignments: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: createAssignment
  // MÔ TẢ: Tạo assignment mới trong Root Collection
  // IMPORTANT: courseId và semesterId phải được set trước khi gọi
  // ========================================
  static Future<String> createAssignment(Assignment assignment) async {
    try {
      print('DEBUG: 📝 Creating assignment: ${assignment.title}');
      print('DEBUG: 📝 CourseId: ${assignment.courseId}');
      print('DEBUG: 📝 SemesterId: ${assignment.semesterId}');

      // ✅ VALIDATION: Đảm bảo courseId và semesterId đã được set
      if (assignment.courseId.isEmpty) {
        throw Exception('CourseId is required for Root Collection');
      }
      if (assignment.semesterId.isEmpty) {
        throw Exception('SemesterId is required for Root Collection');
      }

      // ✅ NEW: Add to Root Collection
      final docRef = await _firestore
          .collection(_assignmentCollectionName)
          .add(assignment.toFirestore());

      print('DEBUG: ✅ Created assignment with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('DEBUG: ❌ Error creating assignment: $e');
      throw Exception('Failed to create assignment: $e');
    }
  }

  // ========================================
  // HÀM: updateAssignment
  // MÔ TẢ: Cập nhật assignment trong Root Collection
  // ========================================
  static Future<void> updateAssignment(Assignment assignment) async {
    try {
      print('DEBUG: 📝 Updating assignment: ${assignment.id}');

      await _firestore
          .collection(_assignmentCollectionName)
          .doc(assignment.id)
          .update(assignment.toFirestore());

      print('DEBUG: ✅ Updated assignment: ${assignment.id}');
    } catch (e) {
      print('DEBUG: ❌ Error updating assignment: $e');
      throw Exception('Failed to update assignment: $e');
    }
  }

  // ========================================
  // HÀM: deleteAssignment
  // MÔ TẢ: Xóa assignment từ Root Collection
  // ========================================
  static Future<void> deleteAssignment(String assignmentId) async {
    try {
      print('DEBUG: 🗑️ Deleting assignment: $assignmentId');

      await _firestore
          .collection(_assignmentCollectionName)
          .doc(assignmentId)
          .delete();

      print('DEBUG: ✅ Deleted assignment: $assignmentId');
    } catch (e) {
      print('DEBUG: ❌ Error deleting assignment: $e');
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // ========================================
  // HÀM: getAssignmentById
  // MÔ TẢ: Lấy assignment cụ thể theo ID từ Root Collection
  // ========================================
  static Future<Assignment?> getAssignmentById(String assignmentId) async {
    try {
      print('DEBUG: 🔍 Fetching assignment by ID: $assignmentId');

      final doc = await _firestore
          .collection(_assignmentCollectionName)
          .doc(assignmentId)
          .get();

      if (!doc.exists) {
        print('DEBUG: ⚠️ Assignment not found: $assignmentId');
        return null;
      }

      final assignment = Assignment.fromFirestore(doc);
      print('DEBUG: ✅ Found assignment: ${assignment.title}');
      return assignment;
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignment by ID: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: getAssignmentsBySemester - NEW METHOD
  // MÔ TẢ: Lấy assignments theo semester (hỗ trợ semester switcher)
  // ========================================
  static Future<List<Assignment>> getAssignmentsBySemester(
      String semesterId) async {
    try {
      print('DEBUG: 🔍 Fetching assignments for semester: $semesterId');

      final snapshot = await _firestore
          .collection(_assignmentCollectionName)
          .where('semesterId', isEqualTo: semesterId)
          .orderBy('deadline', descending: false)
          .get();

      final assignments = <Assignment>[];
      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment doc ${doc.id}: $e');
        }
      }

      print(
          'DEBUG: ✅ Found ${assignments.length} assignments for semester $semesterId');
      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignments by semester: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getUpcomingAssignments - NEW METHOD
  // MÔ TẢ: Lấy assignments sắp đến hạn (cho Dashboard)
  // ========================================
  static Future<List<Assignment>> getUpcomingAssignments({
    String? courseId,
    String? semesterId,
    int limit = 10,
  }) async {
    try {
      print('DEBUG: 🔍 Fetching upcoming assignments');

      Query query = _firestore
          .collection(_assignmentCollectionName)
          .where('deadline', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('deadline', descending: false)
          .limit(limit);

      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      if (semesterId != null) {
        query = query.where('semesterId', isEqualTo: semesterId);
      }

      final snapshot = await query.get();

      final assignments = <Assignment>[];
      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment doc ${doc.id}: $e');
        }
      }

      print('DEBUG: ✅ Found ${assignments.length} upcoming assignments');
      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error fetching upcoming assignments: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getAssignmentsForStudent - NEW METHOD
  // MÔ TẢ: Lấy assignments của student từ enrolled courses (cho Dashboard)
  // ========================================
  static Future<List<Assignment>> getAssignmentsForStudent(
    String studentId,
    List<String> enrolledCourseIds,
  ) async {
    try {
      print('DEBUG: 🔍 Fetching assignments for student: $studentId');
      print('DEBUG: 📚 Enrolled courses: $enrolledCourseIds');

      if (enrolledCourseIds.isEmpty) {
        return [];
      }

      // Firebase có giới hạn 10 items trong whereIn
      final assignments = <Assignment>[];

      // Chia thành chunks nếu > 10 courses
      for (int i = 0; i < enrolledCourseIds.length; i += 10) {
        final chunk = enrolledCourseIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection(_assignmentCollectionName)
            .where('courseId', whereIn: chunk)
            .orderBy('deadline', descending: false)
            .get();

        for (var doc in snapshot.docs) {
          try {
            final assignment = Assignment.fromFirestore(doc);
            assignments.add(assignment);
          } catch (e) {
            print('DEBUG: ⚠️ Error parsing assignment doc ${doc.id}: $e');
          }
        }
      }

      print('DEBUG: ✅ Found ${assignments.length} assignments for student');
      return assignments;
    } catch (e) {
      print('DEBUG: ❌ Error fetching assignments for student: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: listenToAssignments - REAL-TIME
  // MÔ TẢ: Stream để theo dõi assignments real-time
  // ========================================
  static Stream<List<Assignment>> listenToAssignments({
    String? courseId,
    String? semesterId,
  }) {
    Query query = _firestore.collection(_assignmentCollectionName);

    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    if (semesterId != null) {
      query = query.where('semesterId', isEqualTo: semesterId);
    }

    return query
        .orderBy('createdAt', descending: true) // Sort by newest first
        .snapshots()
        .map((snapshot) {
      final assignments = <Assignment>[];
      for (var doc in snapshot.docs) {
        try {
          final assignment = Assignment.fromFirestore(doc);
          assignments.add(assignment);
        } catch (e) {
          print('DEBUG: ⚠️ Error parsing assignment doc ${doc.id}: $e');
        }
      }
      return assignments;
    });
  }

  // ========================================
  // HÀM: listenToAssignment - REAL-TIME (Single Assignment)
  // MÔ TẢ: Stream để theo dõi 1 assignment real-time (for detail page)
  // ========================================
  static Stream<Assignment?> listenToAssignment(String assignmentId) {
    return _firestore
        .collection(_assignmentCollectionName)
        .doc(assignmentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        print('DEBUG: ⚠️ Assignment not found: $assignmentId');
        return null;
      }
      try {
        return Assignment.fromFirestore(snapshot);
      } catch (e) {
        print('DEBUG: ❌ Error parsing assignment: $e');
        return null;
      }
    });
  }

  // ========================================
  // HÀM: bulkDeleteAssignments - CLEANUP
  // MÔ TẢ: Xóa hàng loạt assignments (khi xóa course/semester)
  // ========================================
  static Future<void> bulkDeleteAssignments({
    String? courseId,
    String? semesterId,
  }) async {
    try {
      Query query = _firestore.collection(_assignmentCollectionName);

      if (courseId != null) {
        query = query.where('courseId', isEqualTo: courseId);
      }

      if (semesterId != null) {
        query = query.where('semesterId', isEqualTo: semesterId);
      }

      final snapshot = await query.get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('DEBUG: ✅ Bulk deleted ${snapshot.docs.length} assignments');
    } catch (e) {
      print('DEBUG: ❌ Error bulk deleting assignments: $e');
      throw Exception('Failed to bulk delete assignments: $e');
    }
  }
}
