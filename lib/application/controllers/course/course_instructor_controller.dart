// ========================================
// FILE: course_instructor_controller.dart
// MÔ TẢ: Controller cho Course - Business Logic Layer dành cho GIẢNG VIÊN
// ========================================

import '../../../data/repositories/course/course_instructor_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/course_model.dart';
import '../../../domain/models/validation_result.dart';
import '../../../core/config/users-role.dart';
import 'enrollment_controller.dart';

// ========================================
// CLASS: CourseInstructorController - Business Logic cho Giảng viên
// MÔ TẢ: Xử lý business logic cho Course operations dành cho giảng viên
// 🔄 UPDATED: Tích hợp EnrollmentController thay vì students array
// ========================================
class CourseInstructorController {
  final AuthRepository _authRepository;
  final EnrollmentController _enrollmentController;

  CourseInstructorController({
    required AuthRepository authRepository,
    EnrollmentController? enrollmentController,
  })  : _authRepository = authRepository,
        _enrollmentController = enrollmentController ?? EnrollmentController();

  // ========================================
  // HÀM: getInstructorCourses - Business Logic
  // MÔ TẢ: Lấy courses mà giảng viên phụ trách (Controller logic)
  // ========================================
  Future<List<CourseModel>> getInstructorCourses() async {
    try {
      // 1. Lấy current user và validate role
      final user = await _authRepository.currentUserModel;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can access teaching courses');
      }

      print('DEBUG: 🔑 CourseInstructorController got instructor: ${user.uid}');

      // 2. Lấy courses từ CourseInstructorRepository
      final courses =
          await CourseInstructorRepository.getInstructorCourses(user.uid);

      // 3. Business logic: Additional filtering for active instructor
      return courses
          .where((course) =>
              course.status != 'deleted' && course.status != 'archived')
          .toList();
    } catch (e) {
      print(
          'DEBUG: ❌ CourseInstructorController.getInstructorCourses error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: getInstructorCoursesBySemester - Business Logic theo semester
  // MÔ TẢ: Lấy courses của giảng viên theo semester cụ thể
  // ========================================
  Future<List<CourseModel>> getInstructorCoursesBySemester(
      String semester) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can access teaching courses');
      }

      print('DEBUG: 🔑 Getting instructor courses for semester: $semester');

      // 2. Lấy courses từ Repository
      final courses =
          await CourseInstructorRepository.getInstructorCoursesBySemester(
              user.uid, semester);

      // 3. Business logic: Filter active courses
      return courses.where((course) => course.status == 'active').toList();
    } catch (e) {
      print(
          'DEBUG: ❌ CourseInstructorController.getInstructorCoursesBySemester error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: getCourseById - Get specific course with instructor validation
  // MÔ TẢ: Lấy course theo ID với business validation cho instructor
  // ========================================
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      // 1. Validate user authentication và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can access teaching courses');
      }

      // 2. Get course từ Repository với instructor validation
      final course = await CourseInstructorRepository.getCourseById(courseId,
          instructorUid: user.uid);

      // 3. Business logic: Additional validation
      if (course != null && course.status == 'deleted') {
        return null; // Don't show deleted courses
      }

      return course;
    } catch (e) {
      print('DEBUG: ❌ CourseInstructorController.getCourseById error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: createCourse - Business logic cho việc tạo course mới
  // MÔ TẢ: Instructor có thể tạo course mới
  // Return ValidationResult với thông tin lỗi cụ thể
  // ========================================
  Future<ValidationResult> createCourse(CourseModel course) async {
    try {
      // 1. Validate user and role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        return ValidationResult.generalError(
            'Access denied: Only instructors can create courses');
      }

      // 2. Field-specific business rules validation
      if (course.name.trim().isEmpty) {
        return ValidationResult.fieldError('name', 'Course name is required');
      }

      if (course.code.trim().isEmpty) {
        return ValidationResult.fieldError('code', 'Course code is required');
      }

      if (course.semester.trim().isEmpty) {
        return ValidationResult.fieldError(
            'semester', 'Semester selection is required');
      }

      // Sessions validation (business rule moved from UI)
      if (course.sessions < 5 || course.sessions > 50) {
        return ValidationResult.fieldError(
            'sessions', 'Number of sessions must be between 5 and 50');
      }

      // 3. Check for duplicate course code
      final existingCourses =
          await CourseInstructorRepository.getInstructorCourses(user.uid);
      final duplicateCode = existingCourses.any((existingCourse) =>
          existingCourse.code.toLowerCase() == course.code.toLowerCase());

      if (duplicateCode) {
        return ValidationResult.fieldError(
            'code', 'This course code already exists');
      }

      // 4. Hardcode status to 'active' for all new courses
      final courseWithActiveStatus = course.copyWith(status: 'active');

      // 5. Create course with instructor UID
      final success = await CourseInstructorRepository.createCourse(
          courseWithActiveStatus, user.uid);

      if (success) {
        print(
            'DEBUG: ✅ Course created successfully by instructor: ${user.uid}');
        return ValidationResult.success('Course created successfully');
      } else {
        print('DEBUG: ❌ Failed to create course');
        return ValidationResult.generalError(
            'Failed to create course in database');
      }
    } catch (e) {
      print('DEBUG: ❌ CourseInstructorController.createCourse error: $e');
      return ValidationResult.generalError(
          'An unexpected error occurred: ${e.toString()}');
    }
  }

  // ========================================
  // HÀM: updateCourse - Business logic cho việc cập nhật course
  // MÔ TẢ: Instructor có thể cập nhật course của mình
  // ========================================
  Future<bool> updateCourse(String courseId, CourseModel updatedCourse) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('Access denied: Only instructors can update courses');
      }

      // 2. Business rules validation
      if (updatedCourse.name.trim().isEmpty) {
        throw Exception('Course name cannot be empty');
      }

      // 3. Update course với instructor validation
      final success = await CourseInstructorRepository.updateCourse(
          courseId, updatedCourse, user.uid);

      if (success) {
        print(
            'DEBUG: ✅ Course updated successfully by instructor: ${user.uid}');
      }

      return success;
    } catch (e) {
      print('DEBUG: ❌ CourseInstructorController.updateCourse error: $e');
      return false;
    }
  }

  // ========================================
  // 🔄 UPDATED METHODS - Using EnrollmentController
  // ========================================

  // HÀM: enrollStudentInCourse - Business logic ghi danh student (NEW)
  // MÔ TẢ: Instructor có thể ghi danh students vào course của mình
  // 🔄 SỬ DỤNG: EnrollmentController thay vì array operations
  Future<String> enrollStudentInCourse({
    required String courseId,
    required String studentUid,
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can manage enrollment');
      }

      // 2. Business logic: Check course ownership và status
      final course = await getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found or access denied');
      }

      if (course.status != 'active') {
        throw Exception('Cannot enroll students in inactive course');
      }

      // 3. Validation using EnrollmentController
      final validation = await _enrollmentController.validateEnrollment(
        courseId: courseId,
        userId: studentUid,
      );

      if (!validation['isValid']) {
        throw Exception(validation['reason']);
      }

      // 4. Enroll student via EnrollmentController
      // ❌ BROKEN: enrollStudentInCourse removed for Strict Enrollment
      // TODO: Update UI to use enrollStudentInGroup with groupId parameter
      throw Exception(
          'enrollStudentInCourse removed - use enrollStudentInGroup with groupId');
    } catch (e) {
      print(
          'DEBUG: ❌ CourseInstructorController.enrollStudentInCourse error: $e');
      rethrow;
    }
  }

  // HÀM: unenrollStudentFromCourse - Business logic hủy ghi danh student (NEW)
  // MÔ TẢ: Instructor có thể hủy ghi danh students khỏi course của mình
  // 🔄 SỬ DỤNG: EnrollmentController thay vì array operations
  Future<void> unenrollStudentFromCourse(
      String courseId, String studentUid) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can manage enrollment');
      }

      // 2. Business logic: Validate course ownership
      final course = await getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found or access denied');
      }

      // 3. Check if student is actually enrolled
      final isEnrolled =
          await _enrollmentController.isStudentEnrolled(courseId, studentUid);
      if (!isEnrolled) {
        throw Exception('Student is not enrolled in this course');
      }

      // 4. Unenroll student via EnrollmentController
      await _enrollmentController.unenrollStudentFromCourse(
          courseId, studentUid);
    } catch (e) {
      print(
          'DEBUG: ❌ CourseInstructorController.unenrollStudentFromCourse error: $e');
      rethrow;
    }
  }

  // HÀM: getEnrolledStudents - Lấy danh sách sinh viên đã ghi danh (NEW)
  // MÔ TẢ: Thay thế việc đọc course.students
  // 🔄 SỬ DỤNG: EnrollmentController để lấy danh sách thực tế
  Future<List<Map<String, dynamic>>> getEnrolledStudents(
      String courseId) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('Access denied: Only instructors can view enrollment');
      }

      // 2. Validate course ownership
      final course = await getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found or access denied');
      }

      // 3. Get enrolled students via EnrollmentController
      final enrollments =
          await _enrollmentController.getEnrolledStudents(courseId);

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
      print(
          'DEBUG: ❌ CourseInstructorController.getEnrolledStudents error: $e');
      return [];
    }
  }

  // ========================================
  // DEPRECATED METHODS - Use new enrollment methods instead
  // ========================================

  @Deprecated('Use enrollStudentInCourse() instead')
  Future<bool> addStudentToCourse(String courseId, String studentUid) async {
    throw UnimplementedError('Use enrollStudentInCourse() instead');
  }

  @Deprecated('Use unenrollStudentFromCourse() instead')
  Future<bool> removeStudentFromCourse(
      String courseId, String studentUid) async {
    throw UnimplementedError('Use unenrollStudentFromCourse() instead');
  }

  // ========================================
  // HÀM: getInstructorDashboardStats - Business logic cho dashboard stats
  // MÔ TẢ: Lấy thống kê tổng quan cho instructor dashboard
  // ========================================
  Future<Map<String, dynamic>> getInstructorDashboardStats() async {
    try {
      // 1. Validate user
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can access dashboard stats');
      }

      // 2. Get enrollment stats từ Repository
      final stats =
          await CourseInstructorRepository.getStudentEnrollmentStats(user.uid);

      // 3. Get all courses để tính toán thêm
      final allCourses = await getInstructorCourses();

      // 4. Business logic: Calculate additional metrics
      final currentSemesterCourses = allCourses
          .where((course) =>
              course.status == 'active' && _isCurrentSemester(course.semester))
          .length;

      return {
        ...stats,
        'currentSemesterCourses': currentSemesterCourses,
        'totalSessions':
            allCourses.fold<int>(0, (sum, course) => sum + course.sessions),
        'activeCourses':
            allCourses.where((course) => course.status == 'active').length,
      };
    } catch (e) {
      print(
          'DEBUG: ❌ CourseInstructorController.getInstructorDashboardStats error: $e');
      return {
        'totalCourses': 0,
        'activeCourses': 0,
        'totalStudents': 0,
        'currentSemesterCourses': 0,
        'totalSessions': 0,
      };
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  // Helper để check current semester (có thể customize logic này)
  bool _isCurrentSemester(String semester) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Logic đơn giản: HK1 (8-12), HK2 (1-5), HK3 (6-7)
    if (currentMonth >= 8 && currentMonth <= 12) {
      return semester.contains('HK1') &&
          semester.contains(currentYear.toString());
    } else if (currentMonth >= 1 && currentMonth <= 5) {
      return semester.contains('HK2') &&
          semester.contains(currentYear.toString());
    } else {
      return semester.contains('HK3') &&
          semester.contains(currentYear.toString());
    }
  }
}
