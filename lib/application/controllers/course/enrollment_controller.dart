// ========================================
// FILE: enrollment_controller.dart
// MÔ TẢ: Controller quản lý việc ghi danh sinh viên vào khóa học
// Clean Architecture: Application Layer
// ========================================

import '../../../data/repositories/course/enrollment_repository.dart';
import '../../../domain/models/enrollment_model.dart';

class EnrollmentController {
  final EnrollmentRepository _repository;

  EnrollmentController({
    EnrollmentRepository? repository,
  }) : _repository = repository ?? EnrollmentRepository();

  // ========================================
  // HÀM: enrollStudentInCourse()
  // MÔ TẢ: Ghi danh sinh viên vào khóa học (thay thế addStudentToCourse)
  // ========================================
  Future<String> enrollStudentInCourse({
    required String courseId,
    required String userId,
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      return await _repository.enrollStudent(
        courseId: courseId,
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
      );
    } catch (e) {
      throw Exception('Lỗi ghi danh sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: unenrollStudentFromCourse()
  // MÔ TẢ: Hủy ghi danh sinh viên khỏi khóa học (thay thế removeStudentFromCourse)
  // ========================================
  Future<void> unenrollStudentFromCourse(String courseId, String userId) async {
    try {
      await _repository.unenrollStudent(courseId, userId);
    } catch (e) {
      throw Exception('Lỗi hủy ghi danh sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: getEnrolledStudents()
  // MÔ TẢ: Lấy danh sách sinh viên đã ghi danh trong khóa học (thay thế course.students)
  // ========================================
  Future<List<EnrollmentModel>> getEnrolledStudents(String courseId) async {
    try {
      return await _repository.getStudentsInCourse(courseId);
    } catch (e) {
      throw Exception('Lỗi lấy danh sách sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: getStudentCourses()
  // MÔ TẢ: Lấy danh sách khóa học của sinh viên (truy vấn ngược)
  // ========================================
  Future<List<EnrollmentModel>> getStudentCourses(String userId) async {
    try {
      return await _repository.getCoursesOfStudent(userId);
    } catch (e) {
      throw Exception('Lỗi lấy danh sách khóa học của sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: countStudentsInCourse()
  // MÔ TẢ: Đếm số sinh viên trong khóa học (thay thế course.students.length)
  // ========================================
  Future<int> countStudentsInCourse(String courseId) async {
    try {
      return await _repository.countStudentsInCourse(courseId);
    } catch (e) {
      print('Error counting students: $e');
      return 0;
    }
  }

  // ========================================
  // HÀM: isStudentEnrolled()
  // MÔ TẢ: Kiểm tra sinh viên có trong khóa học không (thay thế course.students.contains)
  // ⚠️ QUAN TRỌNG: Dùng cho logic Group validation
  // ========================================
  Future<bool> isStudentEnrolled(String courseId, String userId) async {
    try {
      return await _repository.isStudentEnrolled(courseId, userId);
    } catch (e) {
      print('Error checking enrollment: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: bulkEnrollStudents()
  // MÔ TẢ: Ghi danh hàng loạt sinh viên (cho CSV import)
  // ========================================
  Future<Map<String, dynamic>> bulkEnrollStudents({
    required String courseId,
    required List<Map<String, String>> students,
  }) async {
    try {
      return await _repository.bulkEnrollStudents(
        courseId: courseId,
        students: students,
      );
    } catch (e) {
      throw Exception('Lỗi ghi danh hàng loạt: $e');
    }
  }

  // ========================================
  // HÀM: validateEnrollment()
  // MÔ TẢ: Business logic validation trước khi ghi danh
  // ========================================
  Future<Map<String, dynamic>> validateEnrollment({
    required String courseId,
    required String userId,
    required int maxCapacity,
  }) async {
    try {
      // Kiểm tra đã ghi danh chưa
      final isAlreadyEnrolled =
          await _repository.isStudentEnrolled(courseId, userId);
      if (isAlreadyEnrolled) {
        return {
          'isValid': false,
          'reason': 'Sinh viên đã được ghi danh trong khóa học này'
        };
      }

      // Kiểm tra capacity
      final currentCount = await _repository.countStudentsInCourse(courseId);
      if (currentCount >= maxCapacity) {
        return {
          'isValid': false,
          'reason': 'Khóa học đã đầy (${currentCount}/${maxCapacity})'
        };
      }

      return {
        'isValid': true,
        'currentCount': currentCount,
        'maxCapacity': maxCapacity,
      };
    } catch (e) {
      return {'isValid': false, 'reason': 'Lỗi validation: $e'};
    }
  }

  // ========================================
  // HÀM: updateEnrollmentStatus()
  // MÔ TẢ: Cập nhật trạng thái enrollment
  // ========================================
  Future<void> updateEnrollmentStatus(
    String courseId,
    String userId,
    String newStatus,
  ) async {
    try {
      await _repository.updateEnrollmentStatus(courseId, userId, newStatus);
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái: $e');
    }
  }

  // ========================================
  // HÀM: getEnrollmentStatistics()
  // MÔ TẢ: Lấy thống kê enrollment cho một khóa học
  // ========================================
  Future<Map<String, int>> getEnrollmentStatistics(String courseId) async {
    try {
      return await _repository.getEnrollmentStatistics(courseId);
    } catch (e) {
      throw Exception('Lỗi lấy thống kê enrollment: $e');
    }
  }

  // ========================================
  // HÀM: listenToEnrollments()
  // MÔ TẢ: Stream để theo dõi thay đổi danh sách sinh viên real-time
  // Dùng cho UI cần cập nhật trực tiếp
  // ========================================
  Stream<List<EnrollmentModel>> listenToEnrollments(String courseId) {
    return _repository.listenToEnrollmentsInCourse(courseId);
  }

  // ========================================
  // HÀM: transferStudent()
  // MÔ TẢ: Chuyển sinh viên từ khóa học này sang khóa học khác
  // ========================================
  Future<void> transferStudent({
    required String fromCourseId,
    required String toCourseId,
    required String userId,
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      // Validation
      final fromValidation = await isStudentEnrolled(fromCourseId, userId);
      if (!fromValidation) {
        throw Exception('Sinh viên không có trong khóa học nguồn');
      }

      final toValidation = await isStudentEnrolled(toCourseId, userId);
      if (toValidation) {
        throw Exception('Sinh viên đã có trong khóa học đích');
      }

      // Thực hiện transfer
      await _repository.unenrollStudent(fromCourseId, userId);
      await _repository.enrollStudent(
        courseId: toCourseId,
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
      );
    } catch (e) {
      throw Exception('Lỗi chuyển sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: getEnrollmentHistory()
  // MÔ TẢ: Lấy lịch sử enrollment của sinh viên (bao gồm cả dropped)
  // ========================================
  Future<List<EnrollmentModel>> getEnrollmentHistory(String userId) async {
    try {
      // Lấy tất cả enrollments (bao gồm cả inactive)
      final allEnrollments = await _repository.getCoursesOfStudent(userId);

      // Sort theo ngày enrollment
      allEnrollments.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));

      return allEnrollments;
    } catch (e) {
      throw Exception('Lỗi lấy lịch sử enrollment: $e');
    }
  }
}
