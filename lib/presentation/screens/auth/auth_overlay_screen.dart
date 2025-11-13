// ========================================
// FILE: auth_overlay_screen.dart
// MÔ TẢ: Màn hình đăng nhập/đăng ký với hiệu ứng overlay
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

  const AuthOverlayScreen({Key? key, this.initialRole = UserRole.student}) : super(key: key);

  @override
  State<AuthOverlayScreen> createState() => _AuthOverlayScreenState();
}

// ========================================
// CLASS: _AuthOverlayScreenState
// MÔ TẢ: State quản lý animation và logic cho màn hình xác thực
// ========================================
class _AuthOverlayScreenState extends State<AuthOverlayScreen> {
  @override
  Widget build(BuildContext context) {
    final role = widget.initialRole;

    return Scaffold(
      backgroundColor: const Color(0xFF003300).withOpacity(0.9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final containerWidth = isWide ? 900.0 : constraints.maxWidth;
          final containerHeight = isWide ? 520.0 : constraints.maxHeight;

          return Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  Expanded(
                    child: _InfoPanel(role: role),
                  ),
                  Expanded(
                    child: LoginForm(role: role),
                  ),
                ],
              ),
            ),
          );
        },
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
                  const Text(
                    'Welcome back!',
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
                    'Đăng nhập bằng tài khoản quản trị để truy cập bảng điều khiển giảng viên.',
                    style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}

// Inline form widgets removed; now using dedicated login form file.



