// ========================================
// FILE: course_instructor_provider.dart
// MÔ TẢ: Course Instructor Provider - Clean Architecture Compliant
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';
import 'package:elearning_management_app/domain/models/validation_result.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'course_instructor_controller.dart';

// ========================================
// Instructor Course State
// ========================================
class InstructorCourseState {
  final List<CourseModel> courses;
  final List<CourseModel> filteredCourses;
  final bool isLoading;
  final String? error;
  final String selectedSemester;
  final String selectedStatus;

  InstructorCourseState({
    this.courses = const [],
    this.filteredCourses = const [],
    this.isLoading = false,
    this.error,
    this.selectedSemester = 'All',
    this.selectedStatus = 'All',
  });

  InstructorCourseState copyWith({
    List<CourseModel>? courses,
    List<CourseModel>? filteredCourses,
    bool? isLoading,
    String? error,
    String? selectedSemester,
    String? selectedStatus,
  }) {
    return InstructorCourseState(
      courses: courses ?? this.courses,
      filteredCourses: filteredCourses ?? this.filteredCourses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedSemester: selectedSemester ?? this.selectedSemester,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }
}

// ========================================
// CLASS: CourseInstructorNotifier
// MÔ TẢ: StateNotifier quản lý logic nghiệp vụ cho Instructor courses
// ========================================
class CourseInstructorNotifier extends StateNotifier<InstructorCourseState> {
  final CourseInstructorController _courseController;

  CourseInstructorNotifier({
    required CourseInstructorController courseController,
  })  : _courseController = courseController,
        super(InstructorCourseState());

  // ========================================
  // HÀM: loadInstructorCourses
  // MÔ TẢ: Tải danh sách khóa học mà instructor đang dạy
  // ========================================
  Future<void> loadInstructorCourses({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('DEBUG: ========== INSTRUCTOR COURSE PROVIDER LOADING ==========');

      // Gọi CourseInstructorController để lấy courses của instructor
      final courses = await _courseController.getInstructorCourses();
      print('DEBUG: ✅ Instructor Provider received ${courses.length} courses');

      if (courses.isNotEmpty) {
        print('DEBUG: 📚 Instructor Courses loaded:');
        for (int i = 0; i < courses.length; i++) {
          final course = courses[i];
          print(
              'DEBUG:   ${i + 1}. ${course.name} (${course.code}) - ${course.semester}');
        }
      } else {
        print('DEBUG: ⚠️ No courses found for current instructor');
      }

      // Áp dụng bộ lọc hiện tại
      final filteredCourses = _applyFilters(courses);
      state = state.copyWith(
          courses: courses, filteredCourses: filteredCourses, isLoading: false);

      print('DEBUG: ===========================================');
    } catch (e) {
      print('DEBUG: ❌ Instructor Provider failed to load courses: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ========================================
  // HÀM: refreshInstructorCourses
  // MÔ TẢ: Làm mới danh sách khóa học của instructor
  // ========================================
  Future<void> refreshInstructorCourses() async {
    await loadInstructorCourses(forceRefresh: true);
  }

  // ========================================
  // HÀM: createCourse
  // MÔ TẢ: Tạo khóa học mới
  // ========================================
  Future<ValidationResult> createCourse(CourseModel course) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _courseController.createCourse(course);

      if (result.isSuccess) {
        // Reload courses after creation
        await loadInstructorCourses(forceRefresh: true);
        state = state.copyWith(isLoading: false, error: null);
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
      }

      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return ValidationResult.generalError(
          'An unexpected error occurred: ${e.toString()}');
    }
  }

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

    // Lọc theo học kì (So sánh với semester name thay vì ID)
    if (state.selectedSemester != 'All') {
      // Debug: In ra để kiểm tra giá trị
      print('DEBUG: 🔍 Filtering by semester: ${state.selectedSemester}');
      print('DEBUG: 📚 Available courses:');
      for (var course in filtered) {
        print('  - ${course.name}: semester="${course.semester}"');
      }

      filtered = filtered.where((course) {
        // So sánh trực tiếp với semester name
        bool matches = course.semester == state.selectedSemester;
        print(
            'DEBUG: Course ${course.name} matches: $matches (semester: "${course.semester}")');
        return matches;
      }).toList();

      print('DEBUG: ✅ Filtered courses count: ${filtered.length}');
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

// ========================================
// PROVIDERS: Instructor Course Providers
// ========================================

// Repository Provider (reuse from course_provider.dart)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.defaultClient();
});

// Instructor Controller Provider
final courseInstructorControllerProvider =
    Provider<CourseInstructorController>((ref) {
  return CourseInstructorController(
    authRepository: ref.read(authRepositoryProvider),
  );
});

// Instructor Course Provider
final courseInstructorProvider =
    StateNotifierProvider<CourseInstructorNotifier, InstructorCourseState>(
        (ref) {
  return CourseInstructorNotifier(
    courseController: ref.read(courseInstructorControllerProvider),
  );
});
