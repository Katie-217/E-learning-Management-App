// ========================================
// FILE: auth_service.dart
// MÔ TẢ: Service xử lý xác thực người dùng
// ========================================

import 'package:dio/dio.dart';
import '../../services/api/api_client.dart';

// ========================================
// CLASS: AuthService
// MÔ TẢ: Service chính cho việc xác thực và đăng nhập
// ========================================
class AuthService {
  AuthService(this._dio);

  final Dio _dio;

  // ========================================
  // HÀM: defaultClient()
  // MÔ TẢ: Factory constructor tạo instance mặc định
  // ========================================
  factory AuthService.defaultClient() => AuthService(ApiClient.instance.client);

  // ========================================
  // HÀM: login()
  // MÔ TẢ: Xử lý đăng nhập người dùng
  // ========================================
  Future<bool> login(String username, String password) async {
    // TODO: Call backend auth API. For now, mock admin/admin
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return username == 'admin' && password == 'admin';
  }
}












