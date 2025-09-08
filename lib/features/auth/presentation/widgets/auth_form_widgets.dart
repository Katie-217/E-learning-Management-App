import 'package:flutter/material.dart';
import '../../../../core/enums/user_role.dart';
import '../../auth_service.dart';

class AuthFormContainer extends StatelessWidget {
  final String title;
  final UserRole role;
  final List<Widget> fields;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final Widget? secondary;
  final Widget? footer;

  
   AuthFormContainer({
    super.key,
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
            decoration: const BoxDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
              ),
              child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  ...fields.expand((e) sync* {
                    yield e;
                    yield const SizedBox(height: 14);
                  }),
                  const SizedBox(height: 4),
                  if (secondary != null) secondary!,
                  const SizedBox(height: 16),
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
                      child: Text(primaryActionLabel,style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
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

class AuthTextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  const AuthTextField({super.key, required this.hint, this.isPassword = false, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        backgroundColor: Colors.white,
      ),
      onPressed: () async {
        final authService = AuthService.defaultClient();
        final user = await authService.signInWithGoogle();

        if (user != null) {
          // Lấy role và điều hướng tới dashboard tương ứng
          final role = await authService.fetchUserRole(user.uid) ?? 'student';
          final routeName = role == 'teacher' ? '/teacher-dashboard' : '/student-dashboard';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập Google thành công: ${user.email ?? ''}')),
          );
          Navigator.of(context).pushReplacementNamed(routeName);
        }else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng nhập Google thất bại, vui lòng thử lại.')),
          );
        }
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


