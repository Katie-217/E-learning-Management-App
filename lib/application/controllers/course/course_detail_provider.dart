import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
// Import file chứa courseInstructorControllerProvider
import 'package:elearning_management_app/application/controllers/course/course_instructor_provider.dart';

// ========================================
// PROVIDER: courseDetailProvider
// MÔ TẢ: Lấy thông tin chi tiết của 1 khóa học theo ID
// LOẠI: AutoDisposeFutureProvider (Tự động hủy khi thoát màn hình để tiết kiệm mem)
// ========================================
final courseDetailProvider = FutureProvider.family.autoDispose<CourseModel?, String>((ref, courseId) async {
  // 1. Lấy Controller từ Provider có sẵn
  final controller = ref.watch(courseInstructorControllerProvider);
  
  // 2. Gọi hàm nghiệp vụ getCourseById
  // Lưu ý: Hàm này đã bao gồm validate instructor ownership
  return await controller.getCourseById(courseId);
});