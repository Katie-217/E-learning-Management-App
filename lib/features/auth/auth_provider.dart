// ========================================
// FILE: auth_provider.dart
// MÔ TẢ: Provider quản lý trạng thái xác thực người dùng
// ========================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========================================
// ENUM: UserRole
// MÔ TẢ: Định nghĩa các vai trò người dùng trong hệ thống
// ========================================
enum UserRole { instructor, student }

// ========================================
// CLASS: AuthState
// MÔ TẢ: Model chứa trạng thái xác thực hiện tại
// ========================================
class AuthState {
  const AuthState({
    required this.isAuthenticated,
    this.username,
    this.role,
  });

  final bool isAuthenticated;
  final String? username;
  final UserRole? role;
}

// ========================================
// CLASS: AuthNotifier
// MÔ TẢ: StateNotifier quản lý thay đổi trạng thái xác thực
// ========================================
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isAuthenticated: false));

  // ========================================
  // HÀM: login()
  // MÔ TẢ: Xử lý đăng nhập và cập nhật trạng thái
  // ========================================
  void login(String username, String password) {
    if (username == 'admin' && password == 'admin') {
      state = const AuthState(isAuthenticated: true, username: 'admin', role: UserRole.instructor);
    } else {
      state = const AuthState(isAuthenticated: true, username: 'student', role: UserRole.student);
    }
  }

  // ========================================
  // HÀM: logout()
  // MÔ TẢ: Xử lý đăng xuất và reset trạng thái
  // ========================================
  void logout() {
    state = const AuthState(isAuthenticated: false);
  }
}

// ========================================
// PROVIDER: authProvider
// MÔ TẢ: Provider chính cho việc quản lý trạng thái xác thực
// ========================================
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());












