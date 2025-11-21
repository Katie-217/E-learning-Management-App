// ========================================
// FILE: student_controller.dart
// MÔ TẢ: Controller sinh viên - Business Logic
// ========================================

import '../../../data/repositories/student/student_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/student_model.dart';
import '../../../core/config/users-role.dart';

class StudentController {
  final AuthRepository _authRepository;

  StudentController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  // ========================================
  // HÀM: createStudent()
  // MÔ TẢ: Tạo hồ sơ sinh viên
  // ⚠️ Lưu ý: User phải được tạo qua Firebase Auth trước
  // ========================================
  Future<String> createStudent({
    required String uid,             // UID từ Firebase Auth
    required String email,
    required String name,
    String? studentCode,             // Mã sinh viên (tùy chọn)
    String? phone,
    String? department,
    String? photoUrl,
  }) async {
    try {
      // // 1. Kiểm tra quyền - chỉ Instructor được tạo
      // final user = await _authRepository.currentUserModel;
      // if (user == null || user.role != UserRole.instructor) {
      //   throw Exception('❌ Chỉ giáo viên mới có quyền tạo sinh viên');
      // }

      // print('DEBUG: ✅ Instructor ${user.uid} đang tạo sinh viên');

      // 2. Validate dữ liệu
      if (email.isEmpty || name.isEmpty) {
        throw Exception('❌ Vui lòng điền đầy đủ thông tin');
      }

      // 3. Tạo StudentSettings
      const settings = StudentSettings(
        language: 'vi',
        theme: 'light',
        status: 'active',
      );

      // 4. Tạo đối tượng StudentModel
      final newStudent = StudentModel(
        uid: uid,
        email: email,
        name: name,
        displayName: name,
        role: 'student',
        createdAt: DateTime.now(),
        settings: settings,
        isActive: true,
        studentCode: studentCode,
        phone: phone,
        photoUrl: photoUrl,
      );

      // 5. Lưu vào Firestore
      final studentId = await StudentRepository.createStudent(newStudent);

      print('DEBUG: ✅ Sinh viên tạo thành công: $studentId');
      return studentId;
    } catch (e) {
      print('DEBUG: ❌ Lỗi tạo sinh viên: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: getStudentById()
  // MÔ TẢ: Lấy thông tin chi tiết sinh viên
  // ========================================
  Future<StudentModel?> getStudentById(String studentUid) async {
    try {
      return await StudentRepository.getStudentById(studentUid);
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy sinh viên: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: getAllStudents()
  // MÔ TẢ: Lấy danh sách tất cả sinh viên
  // ========================================
  Future<List<StudentModel>> getAllStudents() async {
    try {
      return await StudentRepository.getAllStudents();
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách sinh viên: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: updateStudent()
  // MÔ TẢ: Cập nhật thông tin sinh viên
  // ========================================
  Future<bool> updateStudent(StudentModel student) async {
    try {
      // 1. Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền cập nhật');
      }

      // 2. Validate dữ liệu
      if (student.name.isEmpty || student.email.isEmpty) {
        throw Exception('❌ Thông tin không hợp lệ');
      }

      // 3. Cập nhật
      await StudentRepository.updateStudent(student);
      print('DEBUG: ✅ Cập nhật sinh viên thành công');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi cập nhật sinh viên: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: updateStudentProfile()
  // MÔ TẢ: Cập nhật thông tin profile
  // ========================================
  Future<bool> updateStudentProfile(
    String studentUid, {
    String? name,
    String? phone,
    String? department,
    String? studentCode,
  }) async {
    try {
      // Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền cập nhật');
      }

      await StudentRepository.updateStudentProfile(
        studentUid,
        name: name,
        phone: phone,
        department: department,
        studentCode: studentCode,
      );

      print('DEBUG: ✅ Cập nhật profile thành công');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi cập nhật profile: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: deleteStudent()
  // MÔ TẢ: Xóa sinh viên (set inactive)
  // ========================================
  Future<bool> deleteStudent(String studentUid) async {
    try {
      // 1. Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền xóa');
      }

      // 2. Lấy thông tin sinh viên trước khi xóa
      final student = await StudentRepository.getStudentById(studentUid);
      if (student == null) {
        throw Exception('❌ Sinh viên không tồn tại');
      }

      // 3. Kiểm tra sinh viên có đang tham gia course nào không (tùy chọn)
      if (student.courseIds.isNotEmpty) {
        throw Exception(
          '❌ Không thể xóa sinh viên đang tham gia ${student.courseIds.length} course',
        );
      }

      // 4. Xóa (set inactive)
      await StudentRepository.deleteStudent(studentUid);
      print('DEBUG: ✅ Xóa sinh viên thành công');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi xóa sinh viên: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: searchStudents()
  // MÔ TẢ: Tìm kiếm sinh viên
  // ========================================
  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      if (query.isEmpty) {
        return await StudentRepository.getAllStudents();
      }
      return await StudentRepository.searchStudents(query);
    } catch (e) {
      print('DEBUG: ❌ Lỗi tìm kiếm: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: enrollStudentToCourse()
  // MÔ TẢ: Thêm sinh viên vào course
  // ========================================
  Future<bool> enrollStudentToCourse(
    String studentUid,
    String courseId,
  ) async {
    try {
      // 1. Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền enrollment');
      }

      // 2. Kiểm tra sinh viên tồn tại
      final student = await StudentRepository.getStudentById(studentUid);
      if (student == null) {
        throw Exception('❌ Sinh viên không tồn tại');
      }

      // 3. Kiểm tra sinh viên đã enroll course này chưa
      if (student.courseIds.contains(courseId)) {
        throw Exception('❌ Sinh viên đã đang ở trong course này');
      }

      // 4. Thêm
      await StudentRepository.enrollStudentToCourse(studentUid, courseId);
      print('DEBUG: ✅ Enrollment thành công');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi enrollment: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: removeStudentFromCourse()
  // MÔ TẢ: Xóa sinh viên khỏi course
  // ========================================
  Future<bool> removeStudentFromCourse(
    String studentUid,
    String courseId,
  ) async {
    try {
      // 1. Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền thay đổi');
      }

      // 2. Xóa
      await StudentRepository.removeStudentFromCourse(studentUid, courseId);
      print('DEBUG: ✅ Xóa thành công');
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi xóa: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: getStudentsByCourse()
  // MÔ TẢ: Lấy danh sách sinh viên theo course
  // ========================================
  Future<List<StudentModel>> getStudentsByCourse(String courseId) async {
    try {
      return await StudentRepository.getStudentsByCourse(courseId);
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getStudentsByGroup()
  // MÔ TẢ: Lấy danh sách sinh viên theo group
  // ========================================
  Future<List<StudentModel>> getStudentsByGroup(String groupId) async {
    try {
      return await StudentRepository.getStudentsByGroup(groupId);
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: addStudentToGroup()
  // MÔ TẢ: Thêm sinh viên vào group
  // ========================================
  Future<bool> addStudentToGroup(
    String studentUid,
    String groupId,
  ) async {
    try {
      // Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền');
      }

      await StudentRepository.addStudentToGroup(studentUid, groupId);
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: removeStudentFromGroup()
  // MÔ TẢ: Xóa sinh viên khỏi group
  // ========================================
  Future<bool> removeStudentFromGroup(
    String studentUid,
    String groupId,
  ) async {
    try {
      // Kiểm tra quyền
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Chỉ giáo viên mới có quyền');
      }

      await StudentRepository.removeStudentFromGroup(studentUid, groupId);
      return true;
    } catch (e) {
      print('DEBUG: ❌ Lỗi: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: getStudentStatistics()
  // MÔ TẢ: Lấy thống kê sinh viên
  // ========================================
  Future<Map<String, int>> getStudentStatistics() async {
    try {
      return await StudentRepository.getStudentStatistics();
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy thống kê: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // ========================================
  // HÀM: listenToStudents()
  // MÔ TẢ: Stream theo dõi thay đổi sinh viên
  // ========================================
  Stream<List<StudentModel>> listenToStudents() {
    return StudentRepository.listenToStudents();
  }
}