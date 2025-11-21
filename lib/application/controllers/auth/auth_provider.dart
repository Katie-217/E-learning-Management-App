// ========================================
// FILE: auth_provider.dart
// MÔ TẢ: AuthProvider sử dụng AuthRepository duy nhất - Clean Architecture
// ========================================

import 'package:flutter/material.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/auth/user_session_service.dart';
import '../../../domain/models/user_model.dart';
import '../../../../core/config/users-role.dart';

// ========================================
// CLASS: AuthProvider
// MÔ TẢ: Provider cho authentication state - Clean Architecture
// ========================================
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository.defaultClient();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // ========================================
  // HÀM: signIn - Đăng nhập bằng username/password và cập nhật state
  // ========================================
  Future<UserModel?> signIn(String username, String password) async {
    _setLoading(true);
    try {
      final user =
          await _authRepository.signInWithUsernameAndPassword(username, password);
      await UserSessionService.saveUserSession(user);
      _setCurrentUser(user);
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // HÀM: signOut - Đăng xuất và clear state
  // ========================================
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      await UserSessionService.clearUserSession();
      _setCurrentUser(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // HÀM: createAccount - Tạo tài khoản mới
  // ========================================
  Future<UserModel?> createAccount(
      String name, String email, String password, UserRole role) async {
    _setLoading(true);
    try {
      final user =
          await _authRepository.createUserAccount(name, email, password, role);
      await UserSessionService.saveUserSession(user);
      _setCurrentUser(user);
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // HÀM: checkAuthState - Kiểm tra auth state
  // ========================================
  Future<void> checkAuthState() async {
    _setLoading(true);
    try {
      final user = await _authRepository.checkUserSession();
      _setCurrentUser(user);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ========================================
  // PRIVATE METHODS
  // ========================================
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}
