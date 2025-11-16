// ========================================
// FILE: course_student_controller.dart
// MÔ TẢ: Controller cho Student Course Operations - Business Logic Layer
// ========================================

import '../../../data/repositories/course/course_student_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/course_model.dart';
import '../../../core/config/users-role.dart';
import 'enrollment_controller.dart';

// ========================================
// CLASS: CourseStudentController - Business Logic
// MÔ TẢ: Xử lý business logic cho Student Course operations
// 🔄 UPDATED: Tích hợp EnrollmentController thay vì students array
// ========================================
class CourseStudentController {
  final AuthRepository _authRepository;
  final EnrollmentController _enrollmentController;

  CourseStudentController({
    required AuthRepository authRepository,
    EnrollmentController? enrollmentController,
  })  : _authRepository = authRepository,
        _enrollmentController = enrollmentController ?? EnrollmentController();

  // ========================================
  // HÀM: getMyCourses - Business Logic
  // MÔ TẢ: Lấy courses của current user (Controller logic)
  // ========================================
  Future<List<CourseModel>> getMyCourses() async {
    try {
      print('DEBUG: ========== COURSE STUDENT CONTROLLER ==========');

      // 1. Lấy current user ID từ AuthRepository
      final userId = await _authRepository.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('DEBUG: 🔑 CourseStudentController got userId: $userId');

      // 2. Lấy courses từ CourseStudentRepository
      final courses = await CourseStudentRepository.getUserCourses(userId);

      print('DEBUG: 📚 Repository returned ${courses.length} courses');

      // 3. Business logic: Filter active courses for students
      final user = await _authRepository.currentUserModel;
      if (user?.role == UserRole.student) {
        final activeCourses =
            courses.where((course) => course.status == 'active').toList();
        print('DEBUG: 🎓 Student role detected - filtering active courses');
        print('DEBUG: 📊 Before filter: ${courses.length} courses');
        print('DEBUG: 📊 After filter: ${activeCourses.length} active courses');

        if (activeCourses.length < courses.length) {
          final inactiveCount = courses.length - activeCourses.length;
          print('DEBUG: ⚠️ Filtered out $inactiveCount inactive courses');
          for (var course in courses) {
            if (course.status != 'active') {
              print(
                  'DEBUG:   - ${course.name} (${course.code}): status = ${course.status}');
            }
          }
        }

        return activeCourses;
      }

      print(
          'DEBUG: ✅ Returning all ${courses.length} courses (non-student role)');
      print('DEBUG: ===========================================');
      return courses;
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.getMyCourses error: $e');
      print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // ========================================
  // HÀM: getAllCourses - For admin/instructor
  // MÔ TẢ: Lấy tất cả courses (business logic kiểm tra role)
  // ========================================
  Future<List<CourseModel>> getAllCourses() async {
    try {
      // 1. Kiểm tra user role
      final user = await _authRepository.currentUserModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (user.role != UserRole.instructor) {
        throw Exception('Access denied: Insufficient permissions');
      }

      // 2. Lấy tất cả courses từ Repository (instructors can see all courses)
      // Note: This should probably use a different method or different repository for admin functions
      throw UnimplementedError(
          'getAllCourses not implemented for students repository');
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.getAllCourses error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: getCourseById - Get specific course
  // MÔ TẢ: Lấy course theo ID với business validation
  // ========================================
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      // 1. Validate user authentication
      final user = await _authRepository.currentUserModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 2. Get course từ Repository
      final course = await CourseStudentRepository.getCourseById(courseId);

      // 3. Business logic: Check access permissions for students
      // Note: Student counts are now managed by EnrollmentRepository
      // Repository should handle enrollment checking

      return course;
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.getCourseById error: $e');
      rethrow;
    }
  }

  // ========================================
  // 🔄 UPDATED METHOD - enrollCourse using EnrollmentController
  // MÔ TẢ: Business logic cho việc đăng ký course
  // 🔄 SỬ DỤNG: EnrollmentController thay vì direct array operations
  // ========================================
  Future<String> enrollCourse(String courseId) async {
    try {
      // 1. Validate user
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.student) {
        throw Exception('Only students can enroll in courses');
      }

      // 2. Check if course exists and is available
      final course = await CourseStudentRepository.getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found');
      }

      if (course.status != 'active') {
        throw Exception('Course is not available for enrollment');
      }

      // 3. Validation using EnrollmentController
      final validation = await _enrollmentController.validateEnrollment(
        courseId: courseId,
        userId: user.uid,
        maxCapacity: course.maxCapacity,
      );

      if (!validation['isValid']) {
        throw Exception(validation['reason']);
      }

      // 4. ❌ BROKEN: enrollStudentInCourse removed for Strict Enrollment
      // TODO: Update UI to use enrollStudentInGroup with groupId parameter
      throw Exception(
          'enrollStudentInCourse removed - use enrollStudentInGroup with groupId');
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.enrollCourse error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: unenrollCourse - Student unenrollment (NEW)
  // MÔ TẢ: Business logic cho việc hủy đăng ký course
  // 🔄 SỬ DỤNG: EnrollmentController
  // ========================================
  Future<void> unenrollCourse(String courseId) async {
    try {
      // 1. Validate user
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.student) {
        throw Exception('Only students can unenroll from courses');
      }

      // 2. Check if student is actually enrolled
      final isEnrolled =
          await _enrollmentController.isStudentEnrolled(courseId, user.uid);
      if (!isEnrolled) {
        throw Exception('You are not enrolled in this course');
      }

      // 3. Unenroll via EnrollmentController
      await _enrollmentController.unenrollStudentFromCourse(courseId, user.uid);
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.unenrollCourse error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: checkEnrollmentStatus - Check if student is enrolled (NEW)
  // MÔ TẢ: Kiểm tra trạng thái ghi danh của sinh viên
  // 🔄 SỬ DỤNG: EnrollmentController.isStudentEnrolled()
  // ========================================
  Future<bool> checkEnrollmentStatus(String courseId) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null) return false;

      return await _enrollmentController.isStudentEnrolled(courseId, user.uid);
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.checkEnrollmentStatus error: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: getMyEnrollmentHistory - Lấy lịch sử ghi danh (NEW)
  // MÔ TẢ: Lấy tất cả courses mà student đã từng ghi danh
  // 🔄 SỬ DỤNG: EnrollmentController
  // ========================================
  Future<List<Map<String, dynamic>>> getMyEnrollmentHistory() async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.student) {
        throw Exception('Only students can view enrollment history');
      }

      final enrollments =
          await _enrollmentController.getEnrollmentHistory(user.uid);

      return enrollments
          .map((enrollment) => {
                'courseId': enrollment.courseId,
                'enrolledAt': enrollment.enrolledAt,
                'status': enrollment.status,
                'studentName': enrollment.studentName,
                'studentEmail': enrollment.studentEmail,
              })
          .toList();
    } catch (e) {
      print(
          'DEBUG: ❌ CourseStudentController.getMyEnrollmentHistory error: $e');
      return [];
    }
  }
}
