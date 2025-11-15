// ========================================
// FILE: course_repository.dart
// MÔ TẢ: Repository cho Course - Clean Architecture compliant
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/course_model.dart';
import 'enrollment_repository.dart';

class CourseStudentRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'course_of_study';

  // ========================================
  // HÀM: getUserCourses - Clean Architecture with EnrollmentRepository
  // MÔ TẢ: Lấy courses của user thông qua EnrollmentRepository
  // 🔄 SửDỤNG: EnrollmentRepository thay vì students array
  // ========================================
  static Future<List<CourseModel>> getUserCourses(String uid) async {
    try {
      print('DEBUG: 🔍 Getting enrolled courses for user: $uid');

      final enrollmentRepo = EnrollmentRepository();

      // 🔄 Sử DỤNG: EnrollmentRepository để lấy danh sách enrollments
      final enrollments = await enrollmentRepo.getCoursesOfStudent(uid);

      print('DEBUG: 📊 Found ${enrollments.length} enrollments for user');

      if (enrollments.isEmpty) {
        print('DEBUG: 🚨 No enrollments found for user $uid');
        return [];
      }

      // Lấy thông tin chi tiết các courses từ courseIds
      final List<CourseModel> courses = [];

      for (final enrollment in enrollments) {
        try {
          final courseDoc = await _firestore
              .collection(_collectionName)
              .doc(enrollment.courseId)
              .get();

          if (courseDoc.exists) {
            final course = CourseModel.fromFirestore(courseDoc);
            courses.add(course);
            print('DEBUG: ✅ Added course: ${course.name}');
          } else {
            print(
                'DEBUG: ⚠️ Course ${enrollment.courseId} not found in courses collection');
          }
        } catch (e) {
          print('DEBUG: ❌ Error fetching course ${enrollment.courseId}: $e');
        }
      }

      // Sort theo name
      courses.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: ✅ Successfully fetched ${courses.length} courses for user');
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

      // Sort by name on client
      courses.sort((a, b) => a.name.compareTo(b.name));

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
  // HÀM: getCoursesBySemester - Updated to use EnrollmentRepository
  // MÔ TẢ: Lấy courses theo semester cho user
  // 🔄 SỬ DỤNG: EnrollmentRepository
  // ========================================
  static Future<List<CourseModel>> getCoursesBySemester(
      String uid, String semester) async {
    try {
      print('DEBUG: 🔍 Getting courses for user $uid in semester $semester');

      final enrollmentRepo = EnrollmentRepository();

      // Lấy tất cả enrollments của user
      final enrollments = await enrollmentRepo.getCoursesOfStudent(uid);

      if (enrollments.isEmpty) {
        print('DEBUG: 📭 No enrollments found for user');
        return [];
      }

      // Lấy courses và filter theo semester
      final List<CourseModel> courses = [];

      for (final enrollment in enrollments) {
        try {
          final courseDoc = await _firestore
              .collection(_collectionName)
              .doc(enrollment.courseId)
              .get();

          if (courseDoc.exists) {
            final course = CourseModel.fromFirestore(courseDoc);
            if (course.semester == semester) {
              courses.add(course);
            }
          }
        } catch (e) {
          print('DEBUG: ❌ Error fetching course ${enrollment.courseId}: $e');
        }
      }

      // Sort by name
      courses.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: ✅ Found ${courses.length} courses for semester $semester');
      return courses;
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
  // DEPRECATED METHODS - Use EnrollmentRepository instead
  // ========================================

  @Deprecated('Use EnrollmentRepository.enrollStudent() instead')
  static Future<bool> addStudentToCourse(
      String courseId, String studentId) async {
    throw UnimplementedError(
        'This method is deprecated. Use EnrollmentRepository.enrollStudent() instead.');
  }

  @Deprecated('Use EnrollmentRepository.unenrollStudent() instead')
  static Future<bool> removeStudentFromCourse(
      String courseId, String studentId) async {
    throw UnimplementedError(
        'This method is deprecated. Use EnrollmentRepository.unenrollStudent() instead.');
  }

  // ========================================
  // HÀM: getStudentsInCourse - NEW METHOD
  // MÔ TẢ: Lấy danh sách sinh viên trong khóa học
  // 🔄 SửDỤNG: EnrollmentRepository
  // ========================================
  static Future<List<Map<String, dynamic>>> getStudentsInCourse(
      String courseId) async {
    try {
      final enrollmentRepo = EnrollmentRepository();
      final enrollments = await enrollmentRepo.getStudentsInCourse(courseId);

      return enrollments
          .map((enrollment) => {
                'userId': enrollment.userId,
                'studentName': enrollment.studentName,
                'studentEmail': enrollment.studentEmail,
                'enrolledAt': enrollment.enrolledAt,
                'status': enrollment.status,
              })
          .toList();
    } catch (e) {
      print('DEBUG: ❌ Error getting students in course: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: isStudentEnrolledInCourse - NEW METHOD
  // MÔ TẢ: Kiểm tra sinh viên có trong khóa học không
  // 🔄 SửDỤNG: EnrollmentRepository
  // ========================================
  static Future<bool> isStudentEnrolledInCourse(
      String courseId, String userId) async {
    try {
      final enrollmentRepo = EnrollmentRepository();
      return await enrollmentRepo.isStudentEnrolled(courseId, userId);
    } catch (e) {
      print('DEBUG: ❌ Error checking student enrollment: $e');
      return false;
    }
  }
}
