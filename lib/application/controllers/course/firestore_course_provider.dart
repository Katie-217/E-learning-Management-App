import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/course_model.dart';
import '../services/firestore_course_service.dart';

// Provider để lắng nghe thay đổi real-time từ Firestore
final firestoreCoursesProvider = StreamProvider<List<CourseModel>>((ref) {
  return FirestoreCourseService.getCoursesStream();
});

// Provider để lắng nghe thay đổi theo học kì
final firestoreCoursesBySemesterProvider = StreamProvider.family<List<CourseModel>, String>((ref, semester) {
  return FirestoreCourseService.getCoursesBySemesterStream(semester);
});

// Provider để lắng nghe thay đổi theo trạng thái
final firestoreCoursesByStatusProvider = StreamProvider.family<List<CourseModel>, String>((ref, status) {
  return FirestoreCourseService.getCoursesByStatusStream(status);
});

// Provider để lấy khóa học theo ID
final firestoreCourseByIdProvider = FutureProvider.family<CourseModel?, String>((ref, id) {
  return FirestoreCourseService.getCourseById(id);
});

// Provider để tạo khóa học mới
final createCourseProvider = FutureProvider.family<CourseModel?, CourseModel>((ref, course) {
  return FirestoreCourseService.createCourse(course);
});

// Provider để cập nhật khóa học
final updateCourseProvider = FutureProvider.family<CourseModel?, ({String id, CourseModel course})>((ref, params) {
  return FirestoreCourseService.updateCourse(params.id, params.course);
});

// Provider để xóa khóa học
final deleteCourseProvider = FutureProvider.family<bool, String>((ref, id) {
  return FirestoreCourseService.deleteCourse(id);
});
