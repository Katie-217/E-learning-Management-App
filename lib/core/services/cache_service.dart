// ========================================
// FILE: cache_service.dart
// MÔ TẢ: Service quản lý cache dữ liệu local sử dụng Hive
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/course_model.dart';

// ========================================
// CLASS: CacheService
// MÔ TẢ: Service chính cho việc lưu trữ và truy xuất dữ liệu cache
// ========================================
class CacheService {
  // ========================================
  // HẰNG SỐ: Tên các Hive Box
  // MÔ TẢ: Định nghĩa tên cho các box lưu trữ dữ liệu
  // ========================================
  static const String coursesBoxName = 'courses';
  static const String appCacheBoxName = 'app_cache';
  
  // ========================================
  // GETTER: _coursesBox
  // MÔ TẢ: Truy cập box lưu trữ khóa học
  // ========================================
  Box<CourseModel> get _coursesBox => Hive.box<CourseModel>(coursesBoxName);
  
  // ========================================
  // GETTER: _appCacheBox
  // MÔ TẢ: Truy cập box lưu trữ cache chung
  // ========================================
  Box get _appCacheBox => Hive.box(appCacheBoxName);

  // ========================================
  // PHẦN: Course Caching Methods
  // MÔ TẢ: Các phương thức xử lý cache cho khóa học
  // ========================================
  
  // ========================================
  // HÀM: saveCourses()
  // MÔ TẢ: Lưu danh sách khóa học vào cache
  // ========================================
  Future<void> saveCourses(List<CourseModel> courses) async {
    await _coursesBox.clear();
    for (final course in courses) {
      await _coursesBox.put(course.id.toString(), course);
    }
    await _appCacheBox.put('courses_last_updated', DateTime.now().toIso8601String());
  }

  // ========================================
  // HÀM: getCourses()
  // MÔ TẢ: Lấy danh sách khóa học từ cache
  // ========================================
  Future<List<CourseModel>> getCourses() async {
    final courses = _coursesBox.values.toList();
    return courses;
  }

  // ========================================
  // HÀM: getCourse()
  // MÔ TẢ: Lấy một khóa học cụ thể từ cache
  // ========================================
  Future<CourseModel?> getCourse(String id) async {
    return _coursesBox.get(id);
  }

  // ========================================
  // HÀM: clearCourseCache()
  // MÔ TẢ: Xóa cache khóa học
  // ========================================
  Future<void> clearCourseCache() async {
    await _coursesBox.clear();
  }

  // ========================================
  // PHẦN: General App Cache Methods
  // MÔ TẢ: Các phương thức xử lý cache chung cho ứng dụng
  // ========================================
  
  // ========================================
  // HÀM: cacheData()
  // MÔ TẢ: Lưu dữ liệu tùy ý vào cache
  // ========================================
  Future<void> cacheData(String key, dynamic data) async {
    await _appCacheBox.put(key, data);
  }

  // ========================================
  // HÀM: getCachedData()
  // MÔ TẢ: Lấy dữ liệu từ cache theo key
  // ========================================
  T? getCachedData<T>(String key) {
    return _appCacheBox.get(key) as T?;
  }

  // ========================================
  // HÀM: clearCache()
  // MÔ TẢ: Xóa toàn bộ cache
  // ========================================
  Future<void> clearCache() async {
    await _appCacheBox.clear();
    await _coursesBox.clear();
  }

  // ========================================
  // HÀM: isCacheValid()
  // MÔ TẢ: Kiểm tra xem cache có còn hợp lệ không
  // ========================================
  bool isCacheValid({Duration maxAge = const Duration(hours: 1)}) {
    final lastUpdated = _appCacheBox.get('courses_last_updated');
    if (lastUpdated == null) return false;
    
    final lastUpdatedDateTime = DateTime.parse(lastUpdated);
    final now = DateTime.now();
    return now.difference(lastUpdatedDateTime) < maxAge;
  }
}

// ========================================
// PROVIDER: cacheServiceProvider
// MÔ TẢ: Provider cho CacheService
// ========================================
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());
