// ========================================
// FILE: group_controller.dart
// MÔ TẢ: Controller quản lý business logic cho Group operations
// UPDATED: Student management delegated to EnrollmentRepository
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/group/group_repository.dart';
import '../../../data/repositories/course/enrollment_repository.dart';
import '../../../domain/models/group_model.dart';
import '../../../domain/models/enrollment_model.dart';

// ========================================
// PROVIDER: groupControllerProvider
// ========================================
final groupControllerProvider =
    StateNotifierProvider<GroupController, AsyncValue<List<GroupModel>>>(
  (ref) => GroupController(),
);

// ========================================
// CLASS: GroupController - REFACTORED
// NOTE: All student management now goes through EnrollmentRepository
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
  // MÔ TẢ: Lấy tất cả groups mà user tham gia (through enrollments)
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
  // HÀM: getStudentsInGroup - DELEGATE TO ENROLLMENT
  // MÔ TẢ: Lấy danh sách sinh viên trong nhóm từ EnrollmentRepository
  // ========================================
  Future<List<EnrollmentModel>> getStudentsInGroup(String groupId) async {
    try {
      return await _enrollmentRepository.getStudentsInGroup(groupId);
    } catch (e) {
      print('DEBUG: Error getting students in group: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getStudentCount - DELEGATE TO ENROLLMENT
  // MÔ TẢ: Đếm số sinh viên trong nhóm
  // ========================================
  Future<int> getStudentCount(String groupId) async {
    try {
      return await _enrollmentRepository.countStudentsInGroup(groupId);
    } catch (e) {
      print('DEBUG: Error counting students in group: $e');
      return 0;
    }
  }

  // ========================================
  // HÀM: getStudentCurrentGroup
  // MÔ TẢ: Lấy group hiện tại của student trong course
  // ========================================
  Future<String?> getStudentCurrentGroup(String courseId, String userId) async {
    try {
      return await _enrollmentRepository.getStudentCurrentGroup(
          courseId, userId);
    } catch (e) {
      print('DEBUG: Error getting student current group: $e');
      return null;
    }
  }

  // ========================================
  // DEPRECATED METHODS - Use EnrollmentController instead
  // ========================================

  // OLD: addStudentToGroup()
  // NEW: Use EnrollmentController.assignStudentToGroup()

  // OLD: removeStudentFromGroup()
  // NEW: Use EnrollmentController.removeStudentFromGroup()

  // OLD: canStudentJoinGroup()
  // NEW: Use EnrollmentController.validateGroupAssignment()

  // OLD: getStudentGroups()
  // NEW: Use EnrollmentRepository.getStudentCurrentGroup()

  // ========================================
  // HÀM: createGroup
  // MÔ TẢ: Tạo group mới và refresh state
  // ========================================
  Future<String> createGroup({
    required String courseId,
    required String groupName,
    required String groupCode,
    String? description,
  }) async {
    try {
      final groupId = await GroupRepository.createGroup(
        courseId: courseId,
        groupName: groupName,
        groupCode: groupCode,
        description: description,
      );

      // Refresh groups list
      await getGroupsByCourse(courseId);

      return groupId;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // NOTE: All student-group operations now go through EnrollmentController
  // for proper business logic and "1 student per group per course" validation
  // ========================================
}