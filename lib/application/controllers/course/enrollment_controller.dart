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
  // ❌ REMOVED: enrollStudentInCourse() - VIOLATES STRICT ENROLLMENT
  // ❌ REASON: Creates enrollment without groupId ("ghost students")
  // ✅ USE INSTEAD: enrollStudentInGroup() method below
  // ========================================

  // ========================================
  // HÀM: unenrollStudentFromCourse() - STRICT ENROLLMENT
  // MÔ TẢ: Xóa hoàn toàn sinh viên khỏi khóa học (hard delete)
  // RULE: Không soft delete để tránh "ghost students"
  // ========================================
  Future<void> unenrollStudentFromCourse(String courseId, String userId) async {
    try {
      // Hard delete để tuân thủ Strict Enrollment
      await _repository.hardDeleteEnrollment(courseId, userId);
    } catch (e) {
      throw Exception('Lỗi xóa sinh viên khỏi khóa học: $e');
    }
  }

  // ========================================
  // HÀM: enrollStudentInGroup() - STRICT ENROLLMENT AUTHORITY
  // MÔ TẢ: Thêm sinh viên vào khóa học VÀ nhóm cùng lúc (single action)
  // RULE: KHÔNG tồn tại enrollment mà groupId = null
  // ========================================
  Future<String> enrollStudentInGroup({
    required String courseId,
    required String userId,
    required String studentName,
    required String studentEmail,
    required String groupId,
    required int groupMaxMembers,
  }) async {
    try {
      // 1. Validation: Kiểm tra sinh viên đã có trong khóa học chưa
      final isAlreadyEnrolled =
          await _repository.isStudentEnrolled(courseId, userId);
      if (isAlreadyEnrolled) {
        throw Exception('Sinh viên đã được ghi danh trong khóa học này');
      }

      // 2. Validation: Kiểm tra sức chứa nhóm
      final currentCount = await _repository.countStudentsInGroup(groupId);
      if (currentCount >= groupMaxMembers) {
        throw Exception('Nhóm đã đầy ($currentCount/$groupMaxMembers)');
      }

      // 3. Thực hiện enrollment với groupId (Strict Enrollment)
      final enrollmentId = await _repository.enrollStudent(
        courseId: courseId,
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
        groupId: groupId, // ✅ BẮT BUỘC có groupId
      );

      print(
          '✅ STRICT ENROLLMENT: Đã thêm sinh viên $userId vào khóa học $courseId, nhóm $groupId');
      return enrollmentId;
    } catch (e) {
      print('❌ Lỗi thêm sinh viên vào nhóm: $e');
      rethrow;
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
  // HÀM: bulkEnrollStudents() - STRICT ENROLLMENT
  // MÔ TẢ: Import CSV sinh viên vào nhóm (không cho phép enrollment không có nhóm)
  // RULE: BẮT BUỘC phải có groupId
  // ========================================
  Future<Map<String, dynamic>> bulkEnrollStudents({
    required String courseId,
    required String groupId, // ✅ BẮT BUỘC cho Strict Enrollment
    required int groupMaxMembers,
    required List<Map<String, String>> students,
  }) async {
    try {
      // 1. Validation: Kiểm tra sức chứa nhóm trước khi import
      final currentCount = await _repository.countStudentsInGroup(groupId);
      final remainingCapacity = groupMaxMembers - currentCount;

      if (students.length > remainingCapacity) {
        throw Exception(
            'Nhóm không đủ chỗ cho ${students.length} sinh viên. Chỉ còn $remainingCapacity/$groupMaxMembers chỗ trống.');
      }

      // 2. Validation: Kiểm tra trùng lặp trong khóa học (không chỉ nhóm)
      final duplicates = <String>[];
      for (final student in students) {
        final userId = student['userId']!;
        final isEnrolled =
            await _repository.isStudentEnrolled(courseId, userId);
        if (isEnrolled) {
          duplicates.add(userId);
        }
      }

      if (duplicates.isNotEmpty) {
        throw Exception(
            'Các sinh viên sau đã có trong khóa học: ${duplicates.join(", ")}');
      }

      // 3. Thực hiện bulk import với groupId (Strict Enrollment)
      return await _repository.bulkEnrollStudents(
        courseId: courseId,
        groupId: groupId, // ✅ Mọi enrollment đều có groupId
        students: students,
      );
    } catch (e) {
      throw Exception('Lỗi import sinh viên vào nhóm: $e');
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

  // ========================================
  // GROUP MANAGEMENT METHODS - BUSINESS LOGIC AUTHORITY
  // Thực thi quy tắc "1 Sinh viên / 1 Nhóm trong 1 Khóa học"
  // ========================================

  // ========================================
  // ❌ REMOVED: assignStudentToGroup() - VIOLATES STRICT ENROLLMENT
  // ❌ REASON: Assumes students can exist without groups first
  // ✅ USE INSTEAD: enrollStudentInGroup() - adds student to course AND group in single action
  // ========================================

  // ========================================
  // ❌ REMOVED: removeStudentFromGroup() - VIOLATES STRICT ENROLLMENT
  // ❌ REASON: Creates "ghost students" (enrollment without groupId)
  // ✅ USE INSTEAD: unenrollStudentFromCourse() to remove completely, or changeStudentGroup() to move
  // ========================================

  // ========================================
  // HÀM: changeStudentGroup()
  // MÔ TẢ: Chuyển sinh viên từ nhóm hiện tại sang nhóm mới
  // ATOMIC OPERATION: Đảm bảo tính nhất quán dữ liệu
  // ========================================
  Future<bool> changeStudentGroup({
    required String courseId,
    required String userId,
    required String newGroupId,
    required int newGroupMaxMembers,
  }) async {
    try {
      // 1. Validation: Kiểm tra sinh viên có nhóm hiện tại không
      final currentGroup =
          await _repository.getStudentCurrentGroup(courseId, userId);
      if (currentGroup == null) {
        throw Exception(
            'Sinh viên chưa có nhóm. Dùng enrollStudentInGroup() để thêm vào nhóm.');
      }

      if (currentGroup == newGroupId) {
        throw Exception('Sinh viên đã ở trong nhóm này rồi');
      }

      // 2. Validation: Kiểm tra sức chứa nhóm mới
      final newGroupCount = await _repository.countStudentsInGroup(newGroupId);
      if (newGroupCount >= newGroupMaxMembers) {
        throw Exception(
            'Nhóm đích đã đầy (${newGroupCount}/${newGroupMaxMembers})');
      }

      // 3. Thực hiện chuyển nhóm (atomic operation)
      final success = await _repository.changeStudentGroup(
        courseId: courseId,
        userId: userId,
        newGroupId: newGroupId,
      );

      if (success) {
        print(
            '✅ Đã chuyển sinh viên $userId từ nhóm $currentGroup sang nhóm $newGroupId');
      }

      return success;
    } catch (e) {
      print('❌ Lỗi chuyển nhóm: $e');
      rethrow;
    }
  }

  // ========================================
  // ❌ REMOVED: validateGroupAssignment() - VIOLATES STRICT ENROLLMENT
  // ❌ REASON: Assumes students can exist without groups (validates assignment to existing enrollments)
  // ✅ USE INSTEAD: Validation is built into enrollStudentInGroup()
  // ========================================

  // ========================================
  // HÀM: getStudentsInGroup()
  // MÔ TẢ: Lấy danh sách sinh viên trong nhóm
  // ========================================
  Future<List<EnrollmentModel>> getStudentsInGroup(String groupId) async {
    try {
      return await _repository.getStudentsInGroup(groupId);
    } catch (e) {
      throw Exception('Lỗi lấy danh sách sinh viên trong nhóm: $e');
    }
  }

  // ========================================
  // HÀM: getStudentCurrentGroup()
  // MÔ TẢ: Lấy nhóm hiện tại của sinh viên trong khóa học
  // ========================================
  Future<String?> getStudentCurrentGroup(String courseId, String userId) async {
    try {
      return await _repository.getStudentCurrentGroup(courseId, userId);
    } catch (e) {
      print('Lỗi lấy nhóm hiện tại: $e');
      return null;
    }
  }

  // ========================================
  // HÀM: countStudentsInGroup()
  // MÔ TẢ: Đếm số sinh viên trong nhóm
  // ========================================
  Future<int> countStudentsInGroup(String groupId) async {
    try {
      return await _repository.countStudentsInGroup(groupId);
    } catch (e) {
      print('Lỗi đếm sinh viên trong nhóm: $e');
      return 0;
    }
  }

  // ========================================
  // HÀM: isStudentInGroup()
  // MÔ TẢ: Kiểm tra sinh viên có trong nhóm cụ thể không
  // ========================================
  Future<bool> isStudentInGroup({
    required String courseId,
    required String userId,
    required String groupId,
  }) async {
    try {
      return await _repository.isStudentInGroup(
        courseId: courseId,
        userId: userId,
        groupId: groupId,
      );
    } catch (e) {
      print('Lỗi kiểm tra sinh viên trong nhóm: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: getGroupStatistics()
  // MÔ TẢ: Thống kê nhóm cho khóa học
  // ========================================
  Future<Map<String, dynamic>> getGroupStatistics(String courseId) async {
    try {
      final enrollments = await _repository.getStudentsInCourse(courseId);

      final groupCount = <String, int>{};
      int studentsWithoutGroup = 0;

      for (final enrollment in enrollments) {
        // ✅ STRICT ENROLLMENT: groupId is now required, không còn null
        if (enrollment.groupId.isNotEmpty) {
          groupCount[enrollment.groupId] =
              (groupCount[enrollment.groupId] ?? 0) + 1;
        } else {
          // ⚠️ Chỉ để phòng defensive, lý thuyết không bao giờ xảy ra với Strict Enrollment
          studentsWithoutGroup++;
        }
      }

      return {
        'totalStudents': enrollments.length,
        'studentsWithGroup': enrollments.length - studentsWithoutGroup,
        'studentsWithoutGroup':
            studentsWithoutGroup, // Sẽ luôn = 0 với Strict Enrollment
        'groupDistribution': groupCount,
        'totalGroups': groupCount.keys.length,
      };
    } catch (e) {
      throw Exception('Lỗi lấy thống kê nhóm: $e');
    }
  }
}
