// ========================================
// FILE: auth_overlay_screen.dart
// MÔ TẢ: Màn hình đăng nhập/đăng ký với hiệu ứng overlay
// ========================================

import 'package:flutter/material.dart';
import '../../auth/legacy/login_screen.dart';
import '../../../core/enums/user_role.dart';
import '../google_auth_service.dart';
import 'login_form.dart';
import 'register_form.dart';


// ========================================
// CLASS: AuthOverlayScreen
// MÔ TẢ: Widget chính cho màn hình xác thực với overlay
// ========================================
class AuthOverlayScreen extends StatefulWidget {
  final UserRole initialRole;

  const AuthOverlayScreen({Key? key, this.initialRole = UserRole.student}) : super(key: key);

  @override
  State<AuthOverlayScreen> createState() => _AuthOverlayScreenState();
}

// ========================================
// CLASS: _AuthOverlayScreenState
// MÔ TẢ: State quản lý animation và logic cho màn hình xác thực
// ========================================
class _AuthOverlayScreenState extends State<AuthOverlayScreen> {
  // ========================================
  // BIẾN: isLogin
  // MÔ TẢ: Trạng thái hiện tại (đăng nhập hoặc đăng ký)
  // ========================================
  bool isLogin = true; // one form toggles between Login/Register

  // ========================================
  // HÀM: _toRegister()
  // MÔ TẢ: Chuyển sang form đăng ký
  // ========================================
  void _toRegister() => setState(() => isLogin = false);
  
  // ========================================
  // HÀM: _toLogin()
  // MÔ TẢ: Chuyển sang form đăng nhập
  // ========================================
  void _toLogin() => setState(() => isLogin = true);

  // ========================================
  // HÀM: build()
  // MÔ TẢ: Xây dựng giao diện màn hình xác thực
  // ========================================
  @override
  Widget build(BuildContext context) {
    final role = widget.initialRole;

    return Scaffold(
      backgroundColor: const Color(0xFF003300).withOpacity(0.9),
      body: Stack(
        children: [
          LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          return Center(
            child: Container(
              width: isWide ? 900 : constraints.maxWidth,
              height: isWide ? 520 : constraints.maxHeight,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // ========================================
                  // PHẦN: Sliding Form Container
                  // MÔ TẢ: Container chứa form với hiệu ứng slide
                  // ========================================
                  AnimatedAlign(
                    alignment: isLogin ? Alignment.centerRight : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: isLogin
                          ? LoginForm(key: const ValueKey('login'), role: role, onSwitchToRegister: _toRegister)
                          : RegisterForm(key: const ValueKey('register'), initialRole: role, onSwitchToLogin: _toLogin),
                    ),
                  ),

                  // ========================================
                  // PHẦN: Overlay Container
                  // MÔ TẢ: Container thông tin với hiệu ứng slide
                  // ========================================
                  AnimatedAlign(
                    alignment: isLogin ? Alignment.centerLeft : Alignment.centerRight,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1,
                      child: _InfoPanel(
                        role: role,
                        isLogin: isLogin,
                        onPrimary: isLogin ? _toRegister : _toLogin,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
        ],
      ),
    );
  }
}

// ========================================
// CLASS: _InfoPanel
// MÔ TẢ: Panel thông tin bên trái/phải với text và button
// ========================================
class _InfoPanel extends StatelessWidget {
  final UserRole role;
  final bool isLogin;
  final VoidCallback onPrimary;

  const _InfoPanel({required this.role, required this.isLogin, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
        return Container(
      decoration: const BoxDecoration(
         image: DecorationImage(
          image: AssetImage('assets/icons/background-roler.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ========================================
                  // PHẦN: Tiêu đề chính
                  // MÔ TẢ: Text tiêu đề thay đổi theo trạng thái
                  // ========================================
                  Text(
                    isLogin ? 'Hello,\nfriends' : 'Start your\n new experience now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 45,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ========================================
                  // PHẦN: Mô tả
                  // MÔ TẢ: Text mô tả thay đổi theo trạng thái
                  // ========================================
                  Text(
                    isLogin
                        ? 'if you already have an account, login here and have fun'
                        : "If you don't have an account yet, join us and start your journey.",
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  // ========================================
                  // PHẦN: Nút chuyển đổi
                  // MÔ TẢ: Nút để chuyển đổi giữa đăng nhập và đăng ký
                  // ========================================
                  OutlinedButton(
                    onPressed: onPrimary,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(isLogin ? 'Register' : 'Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}

// Inline form widgets removed; now using dedicated files: login_form.dart and register_form.dart.



