import 'package:flutter/material.dart';
import '../../../core/enums/user_role.dart';
import 'widgets/auth_form_widgets.dart';
import '../auth_service.dart';


class RegisterForm extends StatefulWidget {
  final UserRole initialRole;
  final VoidCallback onSwitchToLogin;

  const RegisterForm({super.key, required this.initialRole, required this.onSwitchToLogin});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  late UserRole selectedRole;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService.defaultClient();

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      title: 'Register hire.',
      role: selectedRole,
      fields: [
        AuthTextField(hint: 'Name', controller: nameController),
        AuthTextField(hint: 'Email', controller: emailController),
        AuthTextField(hint: 'Password', isPassword: true, controller: passwordController),
        DropdownButtonFormField<UserRole>(
          value: selectedRole,
          decoration: InputDecoration(
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
          items: const [
            DropdownMenuItem(value: UserRole.student, child: Text('Student')),
            DropdownMenuItem(value: UserRole.teacher, child: Text('Teacher')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => selectedRole = value);
          },
        ),
      ],
      primaryActionLabel: 'Register',
      onPrimaryAction: () async {
        // Kiểm tra input
        if (nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập tên')),
          );
          return;
        }
        if (emailController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập email')),
          );
          return;
        }
        if (passwordController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập mật khẩu')),
          );
          return;
        }
        
        // Hiển thị loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        try {
          final user = await authService.signUp(
            nameController.text.trim(),
            emailController.text.trim(),
            passwordController.text.trim(),
            selectedRole,
          );
          
          // Đóng loading dialog
          Navigator.of(context).pop();
          
          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')),
            );
            // Chuyển về màn hình đăng nhập
            widget.onSwitchToLogin();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng ký thất bại. Vui lòng thử lại.')),
            );
          }
        } catch (e) {
          // Đóng loading dialog
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      },

    );
  }
}


