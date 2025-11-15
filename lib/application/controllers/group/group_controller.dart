// ========================================
// FILE: group_controller.dart
// MÔ TẢ: Controller quản lý business logic cho Group operations
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/group/group_repository.dart';
import '../../../data/repositories/course/enrollment_repository.dart';
import '../../../domain/models/group_model.dart';

// ========================================
// PROVIDER: groupControllerProvider
// ========================================
final groupControllerProvider =
    StateNotifierProvider<GroupController, AsyncValue<List<GroupModel>>>(
  (ref) => GroupController(),
);

// ========================================
// CLASS: GroupController
// ========================================
class GroupController extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();

  GroupController() : super(const AsyncValue.loading());

  // ========================================
  // HÀM: getGroupsByCourse
  // MÔ TẢ: Lấy tất cả groups trong một course
  // ========================================
  Future<void> getGroupsByCourse(String courseId) async {
    try {
      state = const AsyncValue.loading();
      final groups = await GroupRepository.getGroupsByCourse(courseId);
      state = AsyncValue.data(groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // ========================================
  // HÀM: getUserGroups
  // MÔ TẢ: Lấy tất cả groups mà user tham gia
  // ========================================
  Future<void> getUserGroups() async {
    try {
      state = const AsyncValue.loading();
      final groups = await GroupRepository.getAllGroupsForUser();
      state = AsyncValue.data(groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // ========================================
  // HÀM: addStudentToGroup
  // MÔ TẢ: Thêm student vào group với validation
  // ========================================
  Future<bool> addStudentToGroup({
    required String courseId,
    required String groupId,
    required String studentId,
  }) async {
    try {
      // Kiểm tra enrollment trước
      final isEnrolled =
          await _enrollmentRepository.isStudentEnrolled(courseId, studentId);
      if (!isEnrolled) {
        throw Exception('Student is not enrolled in this course');
      }

      // Kiểm tra group có tồn tại không
      final group = await GroupRepository.getGroupById(courseId, groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Kiểm tra group đã full chưa
      if (group.isFull) {
        throw Exception('Group is already full');
      }

      // Kiểm tra student đã có trong group chưa
      if (group.hasStudent(studentId)) {
        throw Exception('Student is already in this group');
      }

      // Thực hiện thêm student
      final success =
          await GroupRepository.addMemberToGroup(courseId, groupId, studentId);

      if (success) {
        // Refresh data
        await getGroupsByCourse(courseId);
      }

      return success;
    } catch (e) {
      print('DEBUG: Error adding student to group: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: removeStudentFromGroup
  // MÔ TẢ: Xóa student khỏi group
  // ========================================
  Future<bool> removeStudentFromGroup({
    required String courseId,
    required String groupId,
    required String studentId,
  }) async {
    try {
      // Kiểm tra group có tồn tại không
      final group = await GroupRepository.getGroupById(courseId, groupId);
      if (group == null) {
        throw Exception('Group not found');
      }

      // Kiểm tra student có trong group không
      if (!group.hasStudent(studentId)) {
        throw Exception('Student is not in this group');
      }

      // Thực hiện xóa student
      final success = await GroupRepository.removeMemberFromGroup(
          courseId, groupId, studentId);

      if (success) {
        // Refresh data
        await getGroupsByCourse(courseId);
      }

      return success;
    } catch (e) {
      print('DEBUG: Error removing student from group: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: canStudentJoinGroup
  // MÔ TẢ: Kiểm tra xem student có thể join group không
  // ========================================
  Future<bool> canStudentJoinGroup({
    required String courseId,
    required String groupId,
    required String studentId,
  }) async {
    try {
      // Kiểm tra enrollment
      final isEnrolled =
          await _enrollmentRepository.isStudentEnrolled(courseId, studentId);
      if (!isEnrolled) {
        return false;
      }

      // Kiểm tra group
      final group = await GroupRepository.getGroupById(courseId, groupId);
      if (group == null || group.isFull || group.hasStudent(studentId)) {
        return false;
      }

      return true;
    } catch (e) {
      print('DEBUG: Error checking if student can join group: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: getStudentGroups
  // MÔ TẢ: Lấy tất cả groups mà một student cụ thể tham gia trong course
  // ========================================
  Future<List<GroupModel>> getStudentGroups({
    required String courseId,
    required String studentId,
  }) async {
    try {
      final allGroups = await GroupRepository.getGroupsByCourse(courseId);
      return allGroups.where((group) => group.hasStudent(studentId)).toList();
    } catch (e) {
      print('DEBUG: Error getting student groups: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: validateGroupOperation
  // MÔ TẢ: Validate trước khi thực hiện bất kỳ operation nào với group
  // ========================================
  Future<String?> validateGroupOperation({
    required String courseId,
    required String groupId,
    required String studentId,
    required String operation, // 'add' hoặc 'remove'
  }) async {
    try {
      // Kiểm tra enrollment
      final isEnrolled =
          await _enrollmentRepository.isStudentEnrolled(courseId, studentId);
      if (!isEnrolled) {
        return 'Student is not enrolled in this course';
      }

      // Kiểm tra group
      final group = await GroupRepository.getGroupById(courseId, groupId);
      if (group == null) {
        return 'Group not found';
      }

      if (operation == 'add') {
        if (group.isFull) {
          return 'Group is already full (${group.maxMembers} members)';
        }
        if (group.hasStudent(studentId)) {
          return 'Student is already in this group';
        }
      } else if (operation == 'remove') {
        if (!group.hasStudent(studentId)) {
          return 'Student is not in this group';
        }
      }

      return null; // No validation errors
    } catch (e) {
      return 'Error validating group operation: $e';
    }
  }
}
