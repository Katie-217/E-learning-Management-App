// ========================================
// FILE: auth_overlay_screen.dart
// MÔ TẢ: Màn hình đăng nhập với hiệu ứng overlay - HỆ THỐNG ĐÓNG
// ========================================

import 'package:flutter/material.dart';
import 'package:elearning_management_app/core/config/users-role.dart';
import 'package:elearning_management_app/presentation/widgets/auth/login_form.dart';

// ========================================
// CLASS: AuthOverlayScreen
// MÔ TẢ: Widget chính cho màn hình xác thực với overlay
// ========================================
class AuthOverlayScreen extends StatefulWidget {
  final UserRole initialRole;

  const AuthOverlayScreen({Key? key, this.initialRole = UserRole.student})
      : super(key: key);

  @override
  State<AuthOverlayScreen> createState() => _AuthOverlayScreenState();
}

// ========================================
// CLASS: _AuthOverlayScreenState
// MÔ TẢ: State quản lý animation và logic cho màn hình xác thực
// ========================================
class _AuthOverlayScreenState extends State<AuthOverlayScreen> {
  // ========================================
  // MÔ TẢ: Hệ thống đóng - CHỈ có đăng nhập, KHÔNG có đăng ký công khai
  // ========================================

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
                  width: isWide ? 700 : constraints.maxWidth,
                  height: isWide ? 500 : constraints.maxHeight,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    children: [
                      // ========================================
                      // PHẦN: Info Panel (Bên trái)
                      // ========================================
                      Expanded(
                        flex: 1,
                        child: _InfoPanel(role: role),
                      ),
                      // ========================================
                      // PHẦN: Login Form (Bên phải)
                      // ========================================
                      Expanded(
                        flex: 1,
                        child: LoginForm(role: role),
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
// MÔ TẢ: Panel thông tin bên trái - HỆ THỐNG ĐÓNG
// ========================================
class _InfoPanel extends StatelessWidget {
  final UserRole role;

  const _InfoPanel({required this.role});

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ========================================
            // PHẦN: Tiêu đề chính
            // ========================================
            const Text(
              'Chào mừng đến với\nHệ thống E-Learning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // ========================================
            // PHẦN: Mô tả hệ thống
            // ========================================
            Text(
              'Đăng nhập với tài khoản được cấp để truy cập hệ thống quản lý học tập trực tuyến',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // ========================================
            // PHẦN: Icon vai trò
            // ========================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role.icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              role.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inline form widgets removed; now using dedicated files: login_form.dart and register_form.dart.
