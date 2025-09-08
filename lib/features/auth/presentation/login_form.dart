import 'package:flutter/material.dart';
import '../../../core/enums/user_role.dart';
import 'widgets/auth_form_widgets.dart';
import '../auth_service.dart';

class LoginForm extends StatefulWidget {
  final UserRole role;
  final VoidCallback onSwitchToRegister;

   const LoginForm({super.key, required this.role, required this.onSwitchToRegister});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService.defaultClient();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = await authService.signIn(email, password);
      if (user != null) {
        final routeName = widget.role == UserRole.teacher ? '/teacher-dashboard' : '/student-dashboard';
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(routeName);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại. Vui lòng kiểm tra thông tin.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormContainer(
      title: 'Login hire.',
      role: widget.role,
      fields: [
        AuthTextField(hint: 'Email', controller: emailController),
        AuthTextField(hint: 'Password', isPassword: true, controller: passwordController),
      ],
      primaryActionLabel: isLoading ? 'Loading...' : 'Login',
      onPrimaryAction: isLoading ? () {} : _handleLogin,
      secondary: Row(
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          const Text('Remember me'),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Forgot password?')),
        ],
      ),
      footer: const Column(
        children: [
          Text("or"),
          SizedBox(height: 12),
          GoogleLoginButton(),
        ],
      ),

    );
  }
}


