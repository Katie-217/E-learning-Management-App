// ========================================
// FILE: course_repository.dart
// MÔ TẢ: Repository cho Course - Clean Architecture compliant
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/course_model.dart';

class CourseStudentRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'course_of_study';

  // ========================================
  // HÀM: getUserCourses - Clean Architecture
  // MÔ TẢ: Lấy courses của user (nhận uid từ Controller)
  // ========================================
  static Future<List<CourseModel>> getUserCourses(String uid) async {
    try {
      print('DEBUG: 🔍 Searching for courses with uid: $uid');

      // Tránh Composite Index - Lọc đơn giản trên client
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('students', arrayContains: uid)
          .get();

      print('DEBUG: 📊 Query result: ${snapshot.docs.length} documents found');

      // Debug: Print document data
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('DEBUG: 📄 Document ${doc.id}: students = ${data['students']}');
      }

      // Sort trên client để tránh composite index
      List<CourseModel> courses =
          snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();

      print('DEBUG: ✅ Parsed ${courses.length} courses successfully');

      // FALLBACK: Nếu không tìm thấy courses với students array, thử lấy tất cả
      if (courses.isEmpty) {
        print(
            'DEBUG: 🔄 No courses found with arrayContains, trying getAllCourses...');
        final allCourses = await getAllCourses();
        print('DEBUG: 📚 Found ${allCourses.length} total courses in database');

        // Debug: Show all course data
        for (var course in allCourses) {
          print(
              'DEBUG: 🔍 Course ${course.id}: name="${course.name}", students=${course.students}');
        }

        // TEMP: Return all courses for now (until we fix students array)
        print('DEBUG: 🚨 TEMPORARY: Returning all courses for testing');
        return allCourses;
      }

      // Sort theo startDate (client-side)
      courses.sort((a, b) => b.startDate.compareTo(a.startDate));

      return courses;
    } catch (e) {
      print('DEBUG: ❌ Error fetching user courses: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getAllCourses - Cho admin/instructor
  // MÔ TẢ: Lấy tất cả courses (không filter)
  // ========================================
  static Future<List<CourseModel>> getAllCourses() async {
    try {
      print(
          'DEBUG: 🔍 getAllCourses - Fetching from collection: $_collectionName');

      // Remove orderBy to avoid field not found error
      final QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();

      print('DEBUG: 📊 getAllCourses found ${snapshot.docs.length} documents');

      // Debug: Log each document
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            'DEBUG: 📄 Doc ${doc.id}: name="${data['name']}", students=${data['students']}');
      }

      final courses =
          snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();

      // Sort by startDate on client
      courses.sort((a, b) => b.startDate.compareTo(a.startDate));

      return courses;
    } catch (e) {
      print('DEBUG: ❌ Error fetching all courses: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getCourseById
  // MÔ TẢ: Lấy course cụ thể theo ID
  // ========================================
  static Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(courseId).get();

      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('DEBUG: ❌ Error fetching course by ID: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: getCoursesBySemester
  // MÔ TẢ: Lấy courses theo semester cho user
  // ========================================
  static Future<List<CourseModel>> getCoursesBySemester(
      String uid, String semester) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('students', arrayContains: uid)
          .where('semester', isEqualTo: semester)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('DEBUG: ❌ Error fetching courses by semester: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: createCourse - Cho instructor
  // MÔ TẢ: Tạo course mới
  // ========================================
  static Future<bool> createCourse(CourseModel course) async {
    try {
      await _firestore.collection(_collectionName).add(course.toFirestore());

      return true;
    } catch (e) {
      print('DEBUG: ❌ Error creating course: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: updateCourse - Cho instructor
  // MÔ TẢ: Cập nhật course
  // ========================================
  static Future<bool> updateCourse(String courseId, CourseModel course) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(courseId)
          .update(course.toFirestore());

      return true;
    } catch (e) {
      print('DEBUG: ❌ Error updating course: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: addStudentToCourse
  // MÔ TẢ: Thêm student vào course
  // ========================================
  static Future<bool> addStudentToCourse(
      String courseId, String studentId) async {
    try {
      await _firestore.collection(_collectionName).doc(courseId).update({
        'students': FieldValue.arrayUnion([studentId])
      });

      return true;
    } catch (e) {
      print('DEBUG: ❌ Error adding student to course: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: removeStudentFromCourse
  // MÔ TẢ: Xóa student khỏi course
  // ========================================
  static Future<bool> removeStudentFromCourse(
      String courseId, String studentId) async {
    try {
      await _firestore.collection(_collectionName).doc(courseId).update({
        'students': FieldValue.arrayRemove([studentId])
      });

      return true;
    } catch (e) {
      print('DEBUG: ❌ Error removing student from course: $e');
      return false;
    }
  }
}
