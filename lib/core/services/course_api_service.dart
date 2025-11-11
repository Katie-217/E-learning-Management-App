import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/course_model.dart';

class CourseApiService {
  
  // Lấy danh sách tất cả khóa học
  static Future<List<CourseModel>> getCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .get();
      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  // Lấy khóa học theo ID
  static Future<CourseModel?> getCourseById(String id) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return CourseModel.fromFirestore(doc);
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  // Lấy khóa học theo học kì
  static Future<List<CourseModel>> getCoursesBySemester(String semester) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('semester', isEqualTo: semester)
          .get();
      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching courses by semester: $e');
      return [];
    }
  }

  // Lấy khóa học theo trạng thái
  static Future<List<CourseModel>> getCoursesByStatus(String status) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching courses by status: $e');
      return [];
    }
  }

  // Tạo khóa học mới
  static Future<CourseModel?> createCourse(CourseModel course) async {
    try {
      final ref = await FirebaseFirestore.instance
          .collection('courses')
          .add(course.toFirestore());
      final created = await ref.get();
      return CourseModel.fromFirestore(created);
    } catch (e) {
      print('Error creating course: $e');
      return null;
    }
  }

  // Cập nhật khóa học
  static Future<CourseModel?> updateCourse(String id, CourseModel course) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(id)
          .update(course.toFirestore());
      final updated = await FirebaseFirestore.instance.collection('courses').doc(id).get();
      if (!updated.exists) return null;
      return CourseModel.fromFirestore(updated);
    } catch (e) {
      print('Error updating course: $e');
      return null;
    }
  }

  // Xóa khóa học
  static Future<bool> deleteCourse(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(id)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }
}
