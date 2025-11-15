// ========================================
// FILE: group_repository.dart
// MÔ TẢ: Repository cho Group - Sub-collection trong course_of_study
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/group_model.dart';
import '../course/enrollment_repository.dart';

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

      // Lấy danh sách courses mà user đã enroll sử dụng EnrollmentRepository
      final enrollmentRepo = EnrollmentRepository();
      final enrollments = await enrollmentRepo.getCoursesOfStudent(user.uid);

      List<GroupModel> allGroups = [];

      for (var enrollment in enrollments) {
        final courseGroups = await getGroupsByCourse(enrollment.courseId);
        // Lọc chỉ groups mà user tham gia
        final userGroups = courseGroups
            .where((group) => group.studentIds.contains(user.uid))
            .toList();
        allGroups.addAll(userGroups);
      }

      print('DEBUG: Total groups for user: ${allGroups.length}');
      return allGroups;
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
  // HÀM: addMemberToGroup
  // MÔ TẢ: Thêm student vào group (với validation enrollment)
  // ========================================
  static Future<bool> addMemberToGroup(
      String courseId, String groupId, String studentId) async {
    try {
      // Kiểm tra xem student có enrolled trong course không
      final enrollmentRepo = EnrollmentRepository();
      final isEnrolled =
          await enrollmentRepo.isStudentEnrolled(courseId, studentId);

      if (!isEnrolled) {
        print('DEBUG: Student is not enrolled in course $courseId');
        return false;
      }

      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_groupSubCollectionName)
          .doc(groupId)
          .update({
        'studentIds': FieldValue.arrayUnion([studentId])
      });

      print('DEBUG: Student added to group successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error adding student to group: $e');
      return false;
    }
  }

  // ========================================
  // HÀM: removeMemberFromGroup
  // MÔ TẢ: Xóa student khỏi group
  // ========================================
  static Future<bool> removeMemberFromGroup(
      String courseId, String groupId, String studentId) async {
    try {
      await _firestore
          .collection(_courseCollectionName)
          .doc(courseId)
          .collection(_groupSubCollectionName)
          .doc(groupId)
          .update({
        'studentIds': FieldValue.arrayRemove([studentId])
      });

      print('DEBUG: Student removed from group successfully');
      return true;
    } catch (e) {
      print('DEBUG: Error removing student from group: $e');
      return false;
    }
  }
}
