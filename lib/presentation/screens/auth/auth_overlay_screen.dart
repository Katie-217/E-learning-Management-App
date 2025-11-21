// ========================================
// FILE: auth_overlay_screen.dart
// MÔ TẢ: Màn hình đăng nhập với hiệu ứng overlay - HỆ THỐNG ĐÓNG
// ========================================

import 'dart:ui';
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
  @override
  Widget build(BuildContext context) {
    final role = widget.initialRole;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/icons/background-roler.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 36,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Icon(
                                role.icon,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Log in to continue experiencing the E-learning system',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),
                            LoginForm(role: role),
                            const SizedBox(height: 18),
                            Center(
                              child: Text(
                                'Closed system - only for granted accounts',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
