import 'package:flutter/material.dart';
import '../../../../core/config/users-role.dart';
import '../../../../data/repositories/auth/auth_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/main_shell.dart';


class RegisterForm extends StatefulWidget {
  final UserRole initialRole;
  final VoidCallback onSwitchToLogin;

  const RegisterForm({super.key, required this.initialRole, required this.onSwitchToLogin});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  late UserRole selectedRole;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final authService = AuthService.defaultClient();
      final user = await authService.signUp(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        selectedRole,
      );
      
      if (user != null) {
        Navigator.of(context).pop(); // Quay lại login form
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng ký: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề
            Text(
              'Đăng ký',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: selectedRole.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Name field
            AuthTextField(
              controller: nameController,
              hintText: 'Họ và tên',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Email field
            AuthTextField(
              controller: emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Password field
            AuthTextField(
              controller: passwordController,
              hintText: 'Mật khẩu',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (value.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Role dropdown
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
                DropdownMenuItem(value: UserRole.student, child: Text('Học sinh')),
                DropdownMenuItem(value: UserRole.teacher, child: Text('Giáo viên')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedRole = value);
              },
            ),
            const SizedBox(height: 24),
            
            // Register button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedRole.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Google login button
            GoogleLoginButton(
              onPressed: () async {
                setState(() => isLoading = true);
                try {
                  final authService = AuthService.defaultClient();
                  final user = await authService.signInWithGoogle();
                  
                  if (user != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainShell())
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi đăng nhập Google: $e')),
                  );
                } finally {
                  if (mounted) setState(() => isLoading = false);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Switch to login
            TextButton(
              onPressed: widget.onSwitchToLogin,
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}


