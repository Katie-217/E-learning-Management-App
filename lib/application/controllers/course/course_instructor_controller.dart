// ========================================
// FILE: course_instructor_controller.dart
// MÔ TẢ: Controller cho Course - Business Logic Layer dành cho GIẢNG VIÊN
// ========================================

import '../../../data/repositories/course/course_instructor_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/course_model.dart';
import '../../../core/config/users-role.dart';

// ========================================
// CLASS: CourseInstructorController - Business Logic cho Giảng viên
// MÔ TẢ: Xử lý business logic cho Course operations dành cho giảng viên
// ========================================
class CourseInstructorController {
  final AuthRepository _authRepository;

  CourseInstructorController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

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
  // ========================================
  Future<bool> createCourse(CourseModel course) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('Access denied: Only instructors can create courses');
      }

      // 2. Business rules validation
      if (course.name.trim().isEmpty) {
        throw Exception('Course name cannot be empty');
      }

      if (course.code.trim().isEmpty) {
        throw Exception('Course code cannot be empty');
      }

      if (course.semester.trim().isEmpty) {
        throw Exception('Semester cannot be empty');
      }

      // 3. Create course với instructor UID
      final success =
          await CourseInstructorRepository.createCourse(course, user.uid);

      if (success) {
        print(
            'DEBUG: ✅ Course created successfully by instructor: ${user.uid}');
      }

      return success;
    } catch (e) {
      print('DEBUG: ❌ CourseInstructorController.createCourse error: $e');
      return false;
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
  // HÀM: addStudentToCourse - Business logic thêm student
  // MÔ TẢ: Instructor có thể thêm students vào course của mình
  // ========================================
  Future<bool> addStudentToCourse(String courseId, String studentUid) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can manage course enrollment');
      }

      // 2. Business logic: Check if course exists and is owned by instructor
      final course = await getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found or access denied');
      }

      if (course.status != 'active') {
        throw Exception('Cannot add students to inactive course');
      }

      // 3. Add student via Repository
      return await CourseInstructorRepository.addStudentToCourse(
          courseId, studentUid, user.uid);
    } catch (e) {
      print('DEBUG: ❌ CourseInstructorController.addStudentToCourse error: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: removeStudentFromCourse - Business logic xóa student
  // MÔ TẢ: Instructor có thể xóa students khỏi course của mình
  // ========================================
  Future<bool> removeStudentFromCourse(
      String courseId, String studentUid) async {
    try {
      // 1. Validate user và role
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception(
            'Access denied: Only instructors can manage course enrollment');
      }

      // 2. Business logic: Validate course ownership
      final course = await getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found or access denied');
      }

      // 3. Remove student via Repository
      return await CourseInstructorRepository.removeStudentFromCourse(
          courseId, studentUid, user.uid);
    } catch (e) {
      print(
          'DEBUG: ❌ CourseInstructorController.removeStudentFromCourse error: $e');
      return false;
    }
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
        'averageProgress': allCourses.isEmpty
            ? 0
            : allCourses.fold<int>(0, (sum, course) => sum + course.progress) ~/
                allCourses.length,
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
        'averageProgress': 0,
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
