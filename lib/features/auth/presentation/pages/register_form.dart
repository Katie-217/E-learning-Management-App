import 'package:flutter/material.dart';
import '../../../../core/config/users-role.dart';
// import 'widgets/auth_form_widgets.dart';
// import 'auth_service.dart';


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
  // final AuthService authService = AuthService.defaultClient();

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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Register Form - Coming Soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(hintText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Register feature coming soon')),
              );
            },
            child: const Text('Register'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onSwitchToLogin,
            child: const Text('Already have an account? Login'),
          ),
        ],
      ),
    );
  }
}


