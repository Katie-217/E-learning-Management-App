
// MÔ TẢ: Provider quản lý trạng thái và logic cho khóa học


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';


//Model chứa trạng thái của danh sách khóa học

class CourseState {
  final List<CourseModel> courses;
  final bool isLoading;
  final String? error;


  // Khởi tạo trạng thái khóa học
 
  CourseState({
    this.courses = const [],
    this.isLoading = false,
    this.error,
  });

 
  // Tạo bản sao với các thay đổi mới
 
  CourseState copyWith({
    List<CourseModel>? courses,
    bool? isLoading,
    String? error,
  }) {
    return CourseState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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


      // Gọi API và cập nhật cache
      // Lấy dữ liệu mới từ server và lưu vào cache
     
      courses = await _apiService.getCourses();
      await _cacheService.saveCourses(courses);
      state = state.copyWith(courses: courses, isLoading: false);
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
  void filterCoursesBySemester(String semester) {
    loadCourses();
  }
}

// Provider chính cho việc quản lý khóa học

final courseProvider = StateNotifierProvider<CourseNotifier, CourseState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return CourseNotifier(apiService, cacheService);
});
