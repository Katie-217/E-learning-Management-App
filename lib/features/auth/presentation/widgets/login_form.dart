import 'package:flutter/material.dart';
import '../../../../core/config/users-role.dart';
import '../../repositories/auth_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../instructor/presentation/pages/instructor_dashboard.dart';

class LoginForm extends StatefulWidget {
  final UserRole role;
  final VoidCallback onSwitchToRegister;

   const LoginForm({super.key, required this.role, required this.onSwitchToRegister});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final authService = AuthService.defaultClient();
      final user = await authService.signIn(_emailController.text.trim(), _passwordController.text.trim());
      
       if (user != null) {
        final role = await authService.fetchUserRole(user.uid);
        final norm = (role ?? '').toString().trim().toLowerCase();
        if (norm == 'teacher' || norm == 'instructor') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InstructorDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      }  else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập thất bại')),
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
              'Đăng nhập',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: widget.role.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Email field
            AuthTextField(
              controller: _emailController,
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
              controller: _passwordController,
              hintText: 'Mật khẩu',
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.role.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Đăng nhập',
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
            
            // Switch to register
            TextButton(
              onPressed: widget.onSwitchToRegister,
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}


