// ========================================
// FILE: group_repository.dart
// MÔ TẢ: Repository cho Group - Sub-collection trong course_of_study
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/group_model.dart';

class GroupRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _courseCollectionName = 'course_of_study';
  static const String _groupSubCollectionName = 'groups';

  // ========================================
  // HÀM: getGroupsByCourse
  // MÔ TẢ: Lấy groups từ sub-collection trong course_of_study
  // ========================================
  static Future<List<GroupModel>> getGroupsByCourse(String courseId) async {
    try {
      print('DEBUG: Fetching groups for course: $courseId');

      final QuerySnapshot snapshot = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_groupSubCollectionName)
          .orderBy('name')
          .get();

      print('DEBUG: Found ${snapshot.docs.length} groups');

      return snapshot.docs
          .map((doc) => GroupModel.fromMap({
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('DEBUG: Error fetching groups: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getAllGroupsForUser
  // MÔ TẢ: Lấy tất cả groups của user từ các course đã enroll
  // ========================================
  static Future<List<GroupModel>> getAllGroupsForUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in for groups');
        return [];
      }

      // ❌ DEPRECATED LOGIC - studentIds no longer exists in GroupModel
      // TODO: Reimplement using EnrollmentRepository to get user's group memberships

      print(
          '⚠️ DEPRECATED: getAllGroupsForUser() needs rewrite using enrollment-based group lookup');

      print('DEBUG: Total groups for user: 0 (deprecated method)');
      return [];
    } catch (e) {
      print('DEBUG: Error fetching user groups: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getGroupById
  // MÔ TẢ: Lấy group cụ thể từ course và group ID
  // ========================================
  static Future<GroupModel?> getGroupById(
      String courseId, String groupId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_groupSubCollectionName)
          .doc(groupId)
          .get();

      if (doc.exists) {
        return GroupModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      return null;
    } catch (e) {
      print('DEBUG: Error fetching group by ID: $e');
      return null;
    }
  }

  // ========================================
  // DEPRECATED: Student management methods moved to EnrollmentRepository
  // MÔ TẢ: GroupRepository now only handles group CRUD operations
  // Use EnrollmentRepository for all student-group assignments
  // ========================================

  // OLD METHOD: addMemberToGroup - DEPRECATED
  // NEW METHOD: Use EnrollmentRepository.assignStudentToGroup()

  // OLD METHOD: removeMemberFromGroup - DEPRECATED
  // NEW METHOD: Use EnrollmentRepository.removeStudentFromGroup()

  // For querying students in group, use:
  // EnrollmentRepository.getStudentsInGroup(groupId)

  // ========================================
  // NOTE: This repository now focuses solely on Group entity CRUD
  // All student-group relationships managed through enrollment pattern
  // ========================================
}
