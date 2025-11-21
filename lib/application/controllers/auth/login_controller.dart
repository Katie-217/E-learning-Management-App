// ========================================
// FILE: login_controller.dart
// MÔ TẢ: Controller cho Login - Clean Architecture Compliant
// ========================================

import 'package:flutter/material.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/auth/user_session_service.dart';
import '../../../domain/models/user_model.dart';
import '../../../../core/config/users-role.dart';

// ========================================
// CLASS: LoginController
// MÔ TẢ: Controller cho Login form - Sử dụng AuthRepository duy nhất
// ========================================
class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository.defaultClient();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your username';
    if (value.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ========================================
  // HÀM: signIn - Sử dụng AuthRepository trả về UserModel
  // MÔ TẢ: Đăng nhập với email/password, lưu session, và navigate
  // ========================================
  Future<UserModel?> signIn(
      BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return null;

    _setLoading(true);
    _setError(null);

    try {
      // Đăng nhập thông qua AuthRepository
      final userModel =
          await _authRepository.signInWithUsernameAndPassword(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      // Lưu session vào SharedPreferences
      await UserSessionService.saveUserSession(userModel);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chào mừng ${userModel.name}!')),
        );

        // Navigate dựa trên role
        final route = userModel.role == UserRole.instructor
            ? '/instructor-dashboard'
            : '/student-dashboard';
        Navigator.of(context).pushReplacementNamed(route);
      }

      return userModel;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Đăng nhập thất bại')),
        );
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
  //   if (!formKey.currentState!.validate()) return;
  //   _setLoading(true);
  //   try {
  //     await ref.read(authProvider).signIn(
  //           emailController.text.trim(),
  //           passwordController.text.trim(),
  //           context,
  //         );
  //     if (context.mounted) {
  //       Navigator.of(context).pushReplacementNamed('/dashboard');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('$e')),
  //     );
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
  //   _setLoading(true);
  //   try {
  //     await ref.read(authProvider).signInWithGoogle(context);
  //     if (context.mounted) {
  //       Navigator.of(context).pushReplacementNamed('/dashboard');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('$e')),
  //     );
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // ========================================
  // HÀM: resetPassword - Sử dụng AuthRepository
  // MÔ TẢ: Gửi email đặt lại mật khẩu
  // ========================================
  Future<void> resetPassword(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset password chưa hỗ trợ cho đăng nhập username'),
      ),
    );
  }

  // ========================================
  // HÀM: signOut
  // MÔ TẢ: Đăng xuất và xóa session
  // ========================================
  Future<void> signOut(BuildContext context) async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      await UserSessionService.clearUserSession();

      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// final loginControllerProvider = ChangeNotifierProvider<LoginController>((ref) {
//   return LoginController();
// });
