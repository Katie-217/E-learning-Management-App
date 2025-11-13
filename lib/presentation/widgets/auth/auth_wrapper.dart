// ========================================
// FILE: auth_wrapper.dart
// MÔ TẢ: Auth Wrapper sử dụng AuthRepository - Clean Architecture
// ========================================

import 'package:flutter/material.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_repository.dart';
import 'package:elearning_management_app/data/repositories/auth/user_session_service.dart';
import 'package:elearning_management_app/domain/models/user_model.dart';
import 'package:elearning_management_app/core/config/users-role.dart';
import 'package:elearning_management_app/presentation/screens/auth/auth_overlay_screen.dart';
import 'package:elearning_management_app/presentation/widgets/common/role_based_dashboard.dart';

// ========================================
// CLASS: AuthWrapper
// MÔ TẢ: Wrapper kiểm tra auth state - Clean Architecture
// ========================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

// ========================================
// CLASS: _AuthWrapperState
// MÔ TẢ: Auth state management sử dụng AuthRepository
// ========================================
class _AuthWrapperState extends State<AuthWrapper> {
  final AuthRepository _authRepository = AuthRepository.defaultClient();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // ========================================
  // HÀM: _checkAuthStatus - Clean Architecture
  // MÔ TẢ: Kiểm tra auth status qua AuthRepository
  // ========================================
  Future<void> _checkAuthStatus() async {
    try {
      // Kiểm tra session trong SharedPreferences
      final hasSession = await UserSessionService.hasValidSession();

      if (hasSession) {
        // Verify với AuthRepository
        final user = await _authRepository.checkUserSession();
        if (user != null) {
          setState(() {
            _currentUser = user;
            _isAuthenticated = true;
            _isLoading = false;
          });
          return;
        }
      }

      // Không có session hợp lệ
      await UserSessionService.clearUserSession();
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    } catch (e) {
      await UserSessionService.clearUserSession();
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_isAuthenticated && _currentUser != null) {
      return RoleBasedDashboard();
    }

    return const MaterialApp(
      home: AuthOverlayScreen(initialRole: UserRole.student),
    );
  }
}
