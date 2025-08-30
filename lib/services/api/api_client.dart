// ========================================
// FILE: api_client.dart
// MÔ TẢ: Client HTTP chính cho việc giao tiếp với API
// ========================================

import 'package:dio/dio.dart';

// ========================================
// CLASS: ApiClient
// MÔ TẢ: Singleton client cho việc gọi API sử dụng Dio
// ========================================
class ApiClient {
  // ========================================
  // CONSTRUCTOR: Private internal constructor
  // MÔ TẢ: Khởi tạo Dio client với cấu hình cơ bản
  // ========================================
  ApiClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.example.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

  // ========================================
  // INSTANCE: Singleton instance
  // MÔ TẢ: Instance duy nhất của ApiClient
  // ========================================
  static final ApiClient instance = ApiClient._internal();

  // ========================================
  // BIẾN: _dio
  // MÔ TẢ: Dio client instance
  // ========================================
  final Dio _dio;

  // ========================================
  // GETTER: client
  // MÔ TẢ: Truy cập Dio client
  // ========================================
  Dio get client => _dio;
}



