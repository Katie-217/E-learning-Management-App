// ========================================
// FILE: auth_overlay_screen.dart
// MÔ TẢ: Màn hình đăng nhập/đăng ký với hiệu ứng overlay
// ========================================

import 'package:flutter/material.dart';
import '../../auth/legacy/login_screen.dart';
import '../../../core/enums/user_role.dart';
import '../google_auth_service.dart';


// ========================================
// CLASS: AuthOverlayScreen
// MÔ TẢ: Widget chính cho màn hình xác thực với overlay
// ========================================
class AuthOverlayScreen extends StatefulWidget {
  final UserRole userRole;

  const AuthOverlayScreen({Key? key, required this.userRole}) : super(key: key);

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
    final role = widget.userRole;

    return Scaffold(
      backgroundColor: const Color(0xFFF3D1DC).withOpacity(0.9), 
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
                          ? _LoginForm(key: const ValueKey('login'), role: role, onSwitchToRegister: _toRegister)
                          : _RegisterForm(key: const ValueKey('register'), role: role, onSwitchToLogin: _toLogin),
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
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icons/background-roler.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================
                  // PHẦN: Tiêu đề chính
                  // MÔ TẢ: Text tiêu đề thay đổi theo trạng thái
                  // ========================================
                  Text(
                    isLogin ? 'Hello\nfriends' : 'Start your\n new experience now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
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

// ========================================
// CLASS: _RegisterForm
// MÔ TẢ: Widget form đăng ký
// ========================================
class _RegisterForm extends StatelessWidget {
  final UserRole role;
  final VoidCallback onSwitchToLogin;

  const _RegisterForm({Key? key, required this.role, required this.onSwitchToLogin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _FormContainer(
      title: 'Register hire.',
      role: role,
      fields: const [
        _TextField(hint: 'Name'),
        _TextField(hint: 'Email'),
        const _TextField(hint: 'Password', isPassword: true),
      ],
      primaryActionLabel: 'Register',
      onPrimaryAction: () {},
      footer: const GoogleLoginButton(),
    );
  }
}

// ========================================
// CLASS: _LoginForm
// MÔ TẢ: Widget form đăng nhập
// ========================================
class _LoginForm extends StatelessWidget {
  final UserRole role;
  final VoidCallback onSwitchToRegister;

  const _LoginForm({Key? key, required this.role, required this.onSwitchToRegister}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _FormContainer(
      title: 'Login hire.',
      role: role,
      fields: const [
        _TextField(hint: 'Email'),
        const _TextField(hint: 'Password', isPassword: true),
      ],
      primaryActionLabel: 'Login',
      onPrimaryAction: () {
        // ========================================
        // PHẦN: Điều hướng theo vai trò
        // MÔ TẢ: Chuyển đến dashboard tương ứng với vai trò
        // ========================================
        final routeName = role == UserRole.teacher ? '/teacher-dashboard' : '/student-dashboard';
        Navigator.of(context).pushReplacementNamed(routeName);
      },
      secondary: Row(
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          const Text('Remember me'),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Forgot password?')),
        ],
      ),
      footer: TextButton(onPressed: onSwitchToRegister, child: const Text('or use your account')),
    );
  }
}

// ========================================
// CLASS: _FormContainer
// MÔ TẢ: Container tái sử dụng cho form với background và styling
// ========================================
class _FormContainer extends StatelessWidget {
  final String title;
  final UserRole role;
  final List<Widget> fields;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final Widget? secondary;
  final Widget? footer;

  const _FormContainer({
    required this.title,
    required this.role,
    required this.fields,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondary,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            decoration: BoxDecoration(
              // ========================================
              // PHẦN: Form Background Image
              // MÔ TẢ: Hình nền cho form
              // ========================================
             
              // ========================================
              // PHẦN: Form Shadow
              // MÔ TẢ: Bóng đổ cho form
              // ========================================
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.35),
              //     blurRadius: 28,
              //     spreadRadius: 2,
              //     offset: const Offset(0, 14),
              //   ),
              // ],
            ),

            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), // Form overlay color
              ),
              child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================
                  // PHẦN: Tiêu đề form
                  // MÔ TẢ: Tiêu đề của form
                  // ========================================
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  // ========================================
                  // PHẦN: Các trường input
                  // MÔ TẢ: Danh sách các trường nhập liệu
                  // ========================================
                  ...fields.expand((e) sync* {
                    yield e;
                    yield const SizedBox(height: 14);
                  }),
                  const SizedBox(height: 4),
                  if (secondary != null) secondary!,
                  const SizedBox(height: 16),
                  // ========================================
                  // PHẦN: Nút hành động chính
                  // MÔ TẢ: Nút đăng nhập/đăng ký
                  // ========================================
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onPrimaryAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: role.primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 2,
                      ),
                      child: Text(primaryActionLabel),
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 12),
                    Center(child: footer!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      ));
  }
}

// ========================================
// CLASS: _TextField
// MÔ TẢ: Widget input field tái sử dụng
// ========================================
class _TextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  const _TextField({required this.hint, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF6F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ========================================
// CLASS: GoogleLoginButton
// MÔ TẢ: Nút đăng nhập bằng Google
// ========================================
class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey), // viền xám mảnh
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // bo tròn
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        backgroundColor: Colors.white,
      ),
      onPressed: () {
        // TODO: xử lý login Google
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
           'assets/icons/logo-google.png',
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 24),
          const Text(
            "Log in with Google",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}



