// ========================================
// FILE: student_controller.dart
// DESCRIPTION: Student Controller - Business Logic (Updated for UserModel)
// ========================================

import '../../../data/repositories/student/student_repository.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/user_model.dart';
import '../../../core/config/users-role.dart';

class StudentController {
  final AuthRepository _authRepository;

  StudentController({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  // ========================================
  // FUNCTION: createStudent()
  // DESCRIPTION: Create a student profile (using UserModel)
  // ========================================
  Future<String> createStudent({
    required String uid,             // UID from Firebase Auth
    required String email,
    required String name,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    try {
      // Validate input data
      if (email.isEmpty || name.isEmpty) {
        throw Exception('❌ Please fill in all required information');
      }

      // Create default UserSettings
      const settings = UserSettings(
        language: 'vi',
        theme: 'light',
        status: 'active',
      );

      // Create UserModel instance with Student role
      final newUser = UserModel(
        uid: uid,
        email: email,
        name: name,
        displayName: name,
        role: UserRole.student,
        createdAt: DateTime.now(),
        settings: settings,
        isActive: true,
        phoneNumber: phoneNumber,
        photoUrl: photoUrl,
        isDefault: false,
      );

      // Save to Firestore via Repository
      final studentId = await StudentRepository.createStudent(newUser);
      return studentId;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // FUNCTION: getStudentById()
  // DESCRIPTION: Get detailed student information by UID
  // ========================================
  Future<UserModel?> getStudentById(String studentUid) async {
    try {
      return await StudentRepository.getStudentById(studentUid);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // FUNCTION: getAllStudents()
  // DESCRIPTION: Retrieve all students
  // ========================================
  Future<List<UserModel>> getAllStudents() async {
    try {
      return await StudentRepository.getAllStudents();
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // FUNCTION: updateStudent()
  // DESCRIPTION: Update full student information
  // ========================================
  Future<bool> updateStudent(UserModel student) async {
    try {
      // Check permission - only instructors allowed
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can update student information');
      }

      // Validate data
      if (student.name.isEmpty || student.email.isEmpty) {
        throw Exception('❌ Invalid information');
      }

      await StudentRepository.updateStudent(student);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: updateStudentProfile()
  // DESCRIPTION: Partial profile update (name & phone only)
  // ========================================
  Future<bool> updateStudentProfile(
    String studentUid, {
    String? name,
    String? phone,
  }) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can update profile');
      }

      await StudentRepository.updateStudentProfile(
        studentUid,
        name: name,
        phone: phone,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: deleteStudent()
  // DESCRIPTION: Soft delete student (set inactive)
  // ========================================
  Future<bool> deleteStudent(String studentUid) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can delete students');
      }

      final student = await StudentRepository.getStudentById(studentUid);
      if (student == null) {
        throw Exception('❌ Student does not exist');
      }

      // Enrollment check is now handled in Repository or skipped
      await StudentRepository.deleteStudent(studentUid);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: searchStudents()
  // DESCRIPTION: Search students by name/email
  // ========================================
  Future<List<UserModel>> searchStudents(String query) async {
    try {
      if (query.isEmpty) {
        return await StudentRepository.getAllStudents();
      }
      return await StudentRepository.searchStudents(query);
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // FUNCTION: enrollStudentToCourse()
  // DESCRIPTION: Enroll a student into a course
  // ========================================
  Future<bool> enrollStudentToCourse(
    String studentUid,
    String courseId,
  ) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can perform enrollment');
      }

      await StudentRepository.enrollStudentToCourse(studentUid, courseId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: removeStudentFromCourse()
  // DESCRIPTION: Remove student from a course
  // ========================================
  Future<bool> removeStudentFromCourse(
    String studentUid,
    String courseId,
  ) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can modify enrollment');
      }

      await StudentRepository.removeStudentFromCourse(studentUid, courseId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: getStudentsByCourse()
  // DESCRIPTION: Get all students enrolled in a specific course
  // ========================================
  Future<List<UserModel>> getStudentsByCourse(String courseId) async {
    try {
      return await StudentRepository.getStudentsByCourse(courseId);
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // FUNCTION: getStudentsByGroup()
  // DESCRIPTION: Get all students in a specific group
  // ========================================
  Future<List<UserModel>> getStudentsByGroup(String groupId) async {
    try {
      return await StudentRepository.getStudentsByGroup(groupId);
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // FUNCTION: addStudentToGroup()
  // DESCRIPTION: Add student to a group
  // ========================================
  Future<bool> addStudentToGroup(
    String studentUid,
    String groupId,
  ) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can manage groups');
      }

      await StudentRepository.addStudentToGroup(studentUid, groupId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: removeStudentFromGroup()
  // DESCRIPTION: Remove student from a group
  // ========================================
  Future<bool> removeStudentFromGroup(
    String studentUid,
    String groupId,
  ) async {
    try {
      final user = await _authRepository.currentUserModel;
      if (user == null || user.role != UserRole.instructor) {
        throw Exception('❌ Only instructors can manage groups');
      }

      await StudentRepository.removeStudentFromGroup(studentUid, groupId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // FUNCTION: getStudentStatistics()
  // DESCRIPTION: Get student statistics (total, active, inactive)
  // ========================================
  Future<Map<String, int>> getStudentStatistics() async {
    try {
      return await StudentRepository.getStudentStatistics();
    } catch (e) {
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // ========================================
  // FUNCTION: listenToStudents()
  // DESCRIPTION: Real-time stream of student list changes
  // ========================================
  Stream<List<UserModel>> listenToStudents() {
    return StudentRepository.listenToStudents();
  }
}