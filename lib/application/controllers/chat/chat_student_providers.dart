// ========================================
// FILE: application/controllers/student/student_providers.dart
// MÔ TẢ: Các Provider của Student để sử dụng trong UI (Riverpod)
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/user_model.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../controllers/student/student_controller.dart';
// 1. AUTH REPOSITORY PROVIDER
// Tạo một instance của AuthRepository để cung cấp cho Controller
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.defaultClient();
});

// 2. STUDENT CONTROLLER PROVIDER
// Khởi tạo Controller và inject AuthRepository vào
final studentControllerProvider = Provider<StudentController>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return StudentController(authRepository: authRepository);
});

// 3. ALL STUDENTS STREAM PROVIDER (QUAN TRỌNG NHẤT)
// Provider này cung cấp danh sách sinh viên Real-time cho Sidebar
// UI sẽ gọi: ref.watch(allStudentsProvider)
final allStudentsProvider = StreamProvider<List<UserModel>>((ref) {
  final controller = ref.watch(studentControllerProvider);
  return controller.listenToStudents();
});

// 4. SEARCH PROVIDERS
// 4a. State lưu từ khóa tìm kiếm hiện tại
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

// 4b. Provider trả về kết quả tìm kiếm dựa trên từ khóa
// Sử dụng autoDispose để tự giải phóng bộ nhớ khi không tìm kiếm nữa
final searchedStudentsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final controller = ref.watch(studentControllerProvider);
  final query = ref.watch(studentSearchQueryProvider);
  
  // Gọi hàm search trong controller
  return controller.searchStudents(query);
});