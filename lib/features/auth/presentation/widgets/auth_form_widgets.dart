import 'package:flutter/material.dart';
import '../../../../core/config/users-role.dart';

// ========================================
// CLASS: AuthFormContainer
// MÔ TẢ: Container chứa form đăng nhập/đăng ký
// ========================================
class AuthFormContainer extends StatelessWidget {
  final String title;
  final UserRole role;
  final List<Widget> fields;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final Widget? secondary;
  final Widget? footer;

  const AuthFormContainer({
    Key? key,
    required this.title,
    required this.role,
    required this.fields,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondary,
    this.footer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ========================================
          // PHẦN: Tiêu đề
          // MÔ TẢ: Tiêu đề form với icon role
          // ========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                role.icon,
                color: role.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: role.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // ========================================
          // PHẦN: Các trường input
          // MÔ TẢ: Danh sách các trường nhập liệu
          // ========================================
          ...fields.map((field) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: field,
          )),
          
          const SizedBox(height: 24),
          
          // ========================================
          // PHẦN: Nút chính
          // MÔ TẢ: Nút thực hiện hành động chính
          // ========================================
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: role.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: Text(
                primaryActionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // ========================================
          // PHẦN: Các tùy chọn phụ
          // MÔ TẢ: Checkbox, link quên mật khẩu, etc.
          // ========================================
          if (secondary != null) ...[
            const SizedBox(height: 16),
            secondary!,
          ],
          
          // ========================================
          // PHẦN: Footer
          // MÔ TẢ: Google login, divider, etc.
          // ========================================
          if (footer != null) ...[
            const SizedBox(height: 24),
            footer!,
          ],
        ],
      ),
    );
  }
}

// ========================================
// CLASS: AuthTextField
// MÔ TẢ: Text field tùy chỉnh cho form auth
// ========================================
class AuthTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;

  const AuthTextField({
    Key? key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.validator,
  }) : super(key: key);

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
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
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF),
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}

// ========================================
// CLASS: GoogleLoginButton
// MÔ TẢ: Nút đăng nhập bằng Google
// ========================================
class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleLoginButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(
          'assets/icons/logo-google.png',
          width: 20,
          height: 20,
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          foregroundColor: const Color(0xFF374151),
        ),
      ),
    );
  }
}