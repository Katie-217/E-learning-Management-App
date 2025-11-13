// ========================================
// FILE: course_controller.dart
// MÔ TẢ: Controller cho Course - Business Logic Layer
// ========================================

import '../../../data/repositories/course/course_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/course_model.dart';

// ========================================
// CLASS: CourseController - Business Logic
// MÔ TẢ: Xử lý business logic cho Course operations
// ========================================
class CourseController {
  final AuthRepository _authRepository;
  final CourseRepository _courseRepository;

  CourseController({
    required AuthRepository authRepository,
    required CourseRepository courseRepository,
  })  : _authRepository = authRepository,
        _courseRepository = courseRepository;

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

      print('DEBUG: 🔑 CourseController got userId: $userId');
      print('DEBUG: 🔑 Expected in Firebase: FT1h3crVGTfKPvPUvh5NzkDzgs2');

      // 2. Lấy courses từ CourseRepository
      final courses = await CourseRepository.getUserCourses(userId);

      // 3. Business logic: Filter active courses for students
      final user = await _authRepository.currentUserModel;
      if (user?.role == 'student') {
        return courses.where((course) => course.status == 'active').toList();
      }

      return courses;
    } catch (e) {
      print('DEBUG: ❌ CourseController.getMyCourses error: $e');
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

      if (user.role != 'admin' && user.role != 'instructor') {
        throw Exception('Access denied: Insufficient permissions');
      }

      // 2. Lấy tất cả courses từ Repository
      return await CourseRepository.getAllCourses();
    } catch (e) {
      print('DEBUG: ❌ CourseController.getAllCourses error: $e');
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
      final course = await CourseRepository.getCourseById(courseId);

      // 3. Business logic: Check access permissions for students
      // Note: CourseModel.students is int (count), actual student list is in Firestore array
      // Repository should handle enrollment checking

      return course;
    } catch (e) {
      print('DEBUG: ❌ CourseController.getCourseById error: $e');
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
      if (user == null || user.role != 'student') {
        throw Exception('Only students can enroll in courses');
      }

      // 2. Check if course exists and is available
      final course = await CourseRepository.getCourseById(courseId);
      if (course == null) {
        throw Exception('Course not found');
      }

      if (course.status != 'active') {
        throw Exception('Course is not available for enrollment');
      }

      // 3. Business rule: Check capacity
      if (course.students >= course.totalStudents) {
        throw Exception('Course is full');
      }

      // 4. TODO: Repository method for enrollment
      // return await CourseRepository.enrollStudent(courseId, user.uid);
      print('DEBUG: Enrollment logic needs Repository method implementation');
      return false;
    } catch (e) {
      print('DEBUG: ❌ CourseController.enrollCourse error: $e');
      return false;
    }
  }
}
