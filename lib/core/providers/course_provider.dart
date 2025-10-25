
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/course_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/course_api_service.dart';
import '../services/firestore_course_service.dart';
import '../services/user_session_service.dart';

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

class CourseNotifier extends StateNotifier<CourseState> {
  final ApiService _apiService;
  final CacheService _cacheService;

  //  Khởi tạo notifier với các service cần thiết

  CourseNotifier(this._apiService, this._cacheService) : super(CourseState());

//  Tải danh sách khóa học từ cache hoặc API

  Future<void> loadCourses({bool forceRefresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<CourseModel> courses;
      
      // 
      // Kiểm tra cache trước khi gọi API
      // Ưu tiên sử dụng dữ liệu cache nếu có
      // 
      // if (!forceRefresh) {
      //   final cachedCourses = await _cacheService.getCourses();
      //   if (cachedCourses.isNotEmpty) {
      //     state = state.copyWith(courses: cachedCourses, isLoading: false);
      //     _loadFreshData(); // refresh background
      //     return;
      //   }
      // }



      // Gọi dữ liệu từ Firestore
      print('DEBUG: ========== COURSE PROVIDER LOADING ==========');
      try {
        courses = await FirestoreCourseService.getCourses();
        print('DEBUG: ✅ Provider received ${courses.length} courses');
        
        if (courses.isNotEmpty) {
          print('DEBUG: 📚 Courses loaded:');
          for (int i = 0; i < courses.length; i++) {
            final course = courses[i];
            print('DEBUG:   ${i + 1}. ${course.name} (${course.code}) - ${course.semester}');
          }
          
          // Lưu session nếu load courses thành công
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await UserSessionService.saveUserSession(user);
            print('DEBUG: ✅ User session saved after successful course loading');
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
        courses: courses, 
        filteredCourses: filteredCourses,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }


  // Tải dữ liệu mới trong background 
  // Future<void> _loadFreshData() async {
  //   try {
  //     final freshCourses = await _apiService.getCourses();
  //     await _cacheService.saveCourses(freshCourses);
  //     state = state.copyWith(courses: freshCourses);
  //   } catch (_) {}
  // }

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
      filtered = filtered.where((course) => 
        course.semester == state.selectedSemester
      ).toList();
    }

    // Lọc theo trạng thái
    if (state.selectedStatus != 'All') {
      filtered = filtered.where((course) => 
        course.status == state.selectedStatus
      ).toList();
    }

    return filtered;
  }

  // Lấy danh sách học kì có sẵn
  List<String> getAvailableSemesters() {
    final semesters = state.courses.map((course) => course.semester).toSet().toList();
    semesters.sort();
    return ['All', ...semesters];
  }

  // Lấy danh sách trạng thái có sẵn
  List<String> getAvailableStatuses() {
    return ['All', 'active', 'completed'];
  }
}

// Provider chính cho việc quản lý khóa học

final courseProvider = StateNotifierProvider<CourseNotifier, CourseState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return CourseNotifier(apiService, cacheService);
});
