// ========================================
// FILE: api_service.dart
// MÔ TẢ: Service xử lý các API calls đến backend server
// ========================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';

// ========================================
// CLASS: ApiService
// MÔ TẢ: Service chính cho việc giao tiếp với API
// ========================================
class ApiService {
  late final Dio _dio;
  static const String baseUrl = 'https://api.university.edu/v1';

  // ========================================
  // CONSTRUCTOR: ApiService
  // MÔ TẢ: Khởi tạo Dio client với cấu hình cơ bản
  // ========================================
  ApiService() {
    // ========================================
    // PHẦN: Cấu hình Dio BaseOptions
    // MÔ TẢ: Thiết lập các tùy chọn cơ bản cho HTTP client
    // ========================================
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // ========================================
    // PHẦN: Thêm Log Interceptor
    // MÔ TẢ: Ghi log các request và response để debug
    // ========================================
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
    
    // ========================================
    // PHẦN: Thêm Custom Interceptors
    // MÔ TẢ: Xử lý request và error handling
    // ========================================
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // ========================================
  // HÀM: getCourses()
  // MÔ TẢ: Lấy danh sách khóa học từ API
  // ========================================
  Future<List<CourseModel>> getCourses({String? semester}) async {
    try {
      await Future.delayed(Duration(seconds: 2));
      return _getMockCourses();
    } catch (e) {
      if (e is DioException) throw _handleDioError(e);
      throw Exception('Failed to load courses: $e');
    }
  }

  // ========================================
  // HÀM: getCourseDetail()
  // MÔ TẢ: Lấy chi tiết một khóa học cụ thể
  // ========================================
  Future<CourseModel> getCourseDetail(String courseId) async {
    await Future.delayed(Duration(milliseconds: 500));
    final courses = _getMockCourses();
    return courses.firstWhere((course) => course.id.toString() == courseId);
  }

  // ========================================
  // HÀM: _handleDioError()
  // MÔ TẢ: Xử lý các lỗi Dio và trả về message phù hợp
  // ========================================
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) return 'Authentication failed. Please login again.';
        if (statusCode == 403) return 'Access denied.';
        if (statusCode == 404) return 'Resource not found.';
        if (statusCode == 500) return 'Server error. Please try again later.';
        return 'Server error: $statusCode';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error. Please check your connection.';
    }
  }

  // ========================================
  // HÀM: _getMockCourses()
  // MÔ TẢ: Trả về danh sách trống (không sử dụng mock data)
  // ========================================
  List<CourseModel> _getMockCourses() {
    return [];
  }
}

// ========================================
// PROVIDER: apiServiceProvider
// MÔ TẢ: Provider cho ApiService
// ========================================
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
