// ========================================
// FILE: course_student_controller.dart
// MÔ TẢ: Controller cho Student Course Operations - Business Logic Layer
// ========================================

import '../../../data/repositories/course/course_student_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/course_model.dart';
import '../../../core/config/users-role.dart';

// ========================================
// CLASS: CourseStudentController - Business Logic
// MÔ TẢ: Xử lý business logic cho Student Course operations
// ========================================
class CourseStudentController {
  final AuthRepository _authRepository;

  CourseStudentController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  // ========================================
  // HÀM: getMyCourses - Business Logic
  // MÔ TẢ: Lấy courses của current user (Controller logic)
  // ========================================
  Future<List<CourseModel>> getMyCourses() async {
    try {
      // 1. Lấy current user ID từ AuthRepository
      final userId = await _authRepository.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('DEBUG: 🔑 CourseStudentController got userId: $userId');
      print('DEBUG: 🔑 Expected in Firebase: FT1h3crVGTfKPvPUvh5NzkDzgs2');

      // 2. Lấy courses từ CourseStudentRepository
      final courses = await CourseStudentRepository.getUserCourses(userId);

      // 3. Business logic: Filter active courses for students
      final user = await _authRepository.currentUserModel;
      if (user?.role == UserRole.student) {
        return courses.where((course) => course.status == 'active').toList();
      }

      return courses;
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.getMyCourses error: $e');
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
      // Note: CourseModel.students is int (count), actual student list is in Firestore array
      // Repository should handle enrollment checking

      return course;
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.getCourseById error: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: enrollCourse - Student enrollment
  // MÔ TẢ: Business logic cho việc đăng ký course
  // ========================================
  Future<bool> enrollCourse(String courseId) async {
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

      // 3. Business rule: Check capacity
      if (course.students >= course.maxCapacity) {
        throw Exception('Course is full');
      }

      // 4. TODO: Repository method for enrollment
      // return await CourseStudentRepository.enrollStudent(courseId, user.uid);
      print('DEBUG: Enrollment logic needs Repository method implementation');
      return false;
    } catch (e) {
      print('DEBUG: ❌ CourseStudentController.enrollCourse error: $e');
      return false;
    }
  }
}
