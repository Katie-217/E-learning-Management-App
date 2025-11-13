// ========================================
// FILE: course_provider.dart
// MÔ TẢ: Course Provider - Clean Architecture Compliant
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/data/repositories/course/course_repository.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'course_controller.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.defaultClient();
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

// Controller Provider
final courseControllerProvider = Provider<CourseController>((ref) {
  return CourseController(
    authRepository: ref.read(authRepositoryProvider),
    courseRepository: ref.read(courseRepositoryProvider),
  );
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
// CLASS: CourseNotifier
// MÔ TẢ: StateNotifier quản lý logic nghiệp vụ cho khóa học
// ========================================
class CourseNotifier extends StateNotifier<CourseState> {
  final CourseController _courseController;

  CourseNotifier({
    required CourseController courseController,
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
      try {
        // Sử dụng CourseController để lấy my courses (bao gồm auth + business logic)
        courses = await _courseController.getMyCourses();
        print('DEBUG: ✅ Provider received ${courses.length} courses');

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

    // Lọc theo học kì
    if (state.selectedSemester != 'All') {
      filtered = filtered
          .where((course) => course.semester == state.selectedSemester)
          .toList();
    }

    // Lọc theo trạng thái
    if (state.selectedStatus != 'All') {
      filtered = filtered
          .where((course) => course.status == state.selectedStatus)
          .toList();
    }

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
// PROVIDER: courseProvider
// MÔ TẢ: Provider chính cho việc quản lý khóa học - Clean Architecture
// ========================================
final courseProvider =
    StateNotifierProvider<CourseNotifier, CourseState>((ref) {
  return CourseNotifier(
    courseController: ref.read(courseControllerProvider),
  );
});
