// ========================================
// FILE: course_provider.dart
// MÔ TẢ: Course Provider - Clean Architecture Compliant
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'course_student_controller.dart';
import 'course_instructor_controller.dart';
import '../../../core/config/users-role.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.defaultClient();
});

// Controller Providers - Role-based
final courseStudentControllerProvider =
    Provider<CourseStudentController>((ref) {
  return CourseStudentController(
    authRepository: ref.read(authRepositoryProvider),
  );
});

final courseInstructorControllerProvider =
    Provider<CourseInstructorController>((ref) {
  return CourseInstructorController(
    authRepository: ref.read(authRepositoryProvider),
  );
});

// Role-based Controller Provider
final courseControllerProvider = Provider<dynamic>((ref) {
  // This provider will be determined by user role at runtime
  // UI should use specific student/instructor providers instead
  throw UnimplementedError(
      'Use courseStudentControllerProvider or courseInstructorControllerProvider directly');
});

// Course state management

class CourseState {
  final List<CourseModel> courses;
  final List<CourseModel> filteredCourses;
  final bool isLoading;
  final String? error;
  final String selectedSemester;
  final String selectedStatus;

  CourseState({
    this.courses = const [],
    this.filteredCourses = const [],
    this.isLoading = false,
    this.error,
    this.selectedSemester = 'All',
    this.selectedStatus = 'All',
  });

  CourseState copyWith({
    List<CourseModel>? courses,
    List<CourseModel>? filteredCourses,
    bool? isLoading,
    String? error,
    String? selectedSemester,
    String? selectedStatus,
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      filteredCourses: filteredCourses ?? this.filteredCourses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedSemester: selectedSemester ?? this.selectedSemester,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

// StateNotifier quản lý logic nghiệp vụ cho khóa học

// ========================================
// CLASS: CourseStudentNotifier
// MÔ TẢ: StateNotifier quản lý logic nghiệp vụ cho Student courses
// ========================================
class CourseStudentNotifier extends StateNotifier<CourseState> {
  final CourseStudentController _courseController;

  CourseStudentNotifier({
    required CourseStudentController courseController,
  })  : _courseController = courseController,
        super(CourseState());

//  Tải danh sách khóa học từ cache hoặc API

  Future<void> loadCourses({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<CourseModel> courses;

      // Đã loại bỏ cache logic để tuân thủ Clean Architecture

      // Gọi dữ liệu từ CourseController theo Clean Architecture
      print('DEBUG: ========== COURSE PROVIDER LOADING ==========');
      print('DEBUG: 🚀 Starting to load courses...');
      try {
        // Sử dụng CourseController để lấy my courses (bao gồm auth + business logic)
        print('DEBUG: 📞 Calling _courseController.getMyCourses()...');
        courses = await _courseController.getMyCourses();
        print('DEBUG: ✅ Provider received ${courses.length} courses from controller');

        if (courses.isNotEmpty) {
          print('DEBUG: 📚 Courses loaded:');
          for (int i = 0; i < courses.length; i++) {
            final course = courses[i];
            print(
                'DEBUG:   ${i + 1}. ${course.name} (${course.code}) - ${course.semester}');
          }
        } else {
          print('DEBUG: ⚠️ No courses found for current user');
        }
      } catch (e) {
        print('DEBUG: ❌ Provider failed to load courses: $e');
        courses = [];
      }
      print('DEBUG: ===========================================');

      // Áp dụng bộ lọc hiện tại
      final filteredCourses = _applyFilters(courses);
      
      print('DEBUG: 📊 Course Provider State Update:');
      print('DEBUG:   - Total courses loaded: ${courses.length}');
      print('DEBUG:   - Filtered courses: ${filteredCourses.length}');
      print('DEBUG:   - Selected semester: ${state.selectedSemester}');
      print('DEBUG:   - Selected status: ${state.selectedStatus}');
      
      state = state.copyWith(
          courses: courses, filteredCourses: filteredCourses, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ========================================
  // HÀM: refreshCourses
  // MÔ TẢ: Làm mới danh sách khóa học
  // ========================================

  Future<void> refreshCourses() async {
    await loadCourses(forceRefresh: true);
  }

  // ========================================
  // Lọc khóa học theo học kì
  void filterCoursesBySemester(String semester) {
    state = state.copyWith(selectedSemester: semester);
    final filteredCourses = _applyFilters(state.courses);
    state = state.copyWith(filteredCourses: filteredCourses);
  }

  // Lọc khóa học theo trạng thái
  void filterCoursesByStatus(String status) {
    state = state.copyWith(selectedStatus: status);
    final filteredCourses = _applyFilters(state.courses);
    state = state.copyWith(filteredCourses: filteredCourses);
  }

  // Áp dụng tất cả bộ lọc
  List<CourseModel> _applyFilters(List<CourseModel> courses) {
    List<CourseModel> filtered = courses;
    
    print('DEBUG: 🔍 Applying filters to ${courses.length} courses');
    print('DEBUG:   - Before filter: ${filtered.length} courses');

    // Lọc theo học kì
    if (state.selectedSemester != 'All') {
      final beforeSemester = filtered.length;
      filtered = filtered
          .where((course) => course.semester == state.selectedSemester)
          .toList();
      print('DEBUG:   - After semester filter (${state.selectedSemester}): ${filtered.length} courses (removed ${beforeSemester - filtered.length})');
    }

    // Lọc theo trạng thái
    if (state.selectedStatus != 'All') {
      final beforeStatus = filtered.length;
      filtered = filtered
          .where((course) => course.status == state.selectedStatus)
          .toList();
      print('DEBUG:   - After status filter (${state.selectedStatus}): ${filtered.length} courses (removed ${beforeStatus - filtered.length})');
    }

    print('DEBUG:   - Final filtered: ${filtered.length} courses');
    return filtered;
  }

  // Lấy danh sách học kì có sẵn
  List<String> getAvailableSemesters() {
    final semesters =
        state.courses.map((course) => course.semester).toSet().toList();
    semesters.sort();
    return ['All', ...semesters];
  }

  // Lấy danh sách trạng thái có sẵn
  List<String> getAvailableStatuses() {
    return ['All', 'active', 'completed'];
  }
}

// Provider chính cho việc quản lý khóa học

// ========================================
// PROVIDERS: Role-based Course Providers
// MÔ TẢ: Providers theo role cho việc quản lý khóa học - Clean Architecture
// ========================================

// Student Course Provider
final courseStudentProvider =
    StateNotifierProvider<CourseStudentNotifier, CourseState>((ref) {
  return CourseStudentNotifier(
    courseController: ref.read(courseStudentControllerProvider),
  );
});

// Instructor Course Provider - will be implemented separately
// final courseInstructorProvider = StateNotifierProvider<CourseInstructorNotifier, CourseState>((ref) {
//   return CourseInstructorNotifier(
//     courseController: ref.read(courseInstructorControllerProvider),
//   );
// });

// Legacy provider for backward compatibility - delegates to student provider
final courseProvider = courseStudentProvider;
