import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/config/users-role.dart';
// import 'widgets/auth_form_widgets.dart';
import '../controllers/login_controller.dart';

class LoginForm extends StatefulWidget {
  final UserRole role;
  final VoidCallback onSwitchToRegister;

   const LoginForm({super.key, required this.role, required this.onSwitchToRegister});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final LoginController controller;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = LoginController();
    // controller = ref.read(loginControllerProvider);
  }

  Future<void> _handleLogin() async {
    final email = controller.emailController.text.trim();
    final password = controller.passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // await controller.signIn(context, ref, GlobalKey<FormState>());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login feature coming soon')),
      );
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Login Form - Coming Soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: controller.emailController,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            child: Text(isLoading ? 'Loading...' : 'Login'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onSwitchToRegister,
            child: const Text('Don\'t have an account? Register'),
          ),
        ],
      ),
    );
  }
}


