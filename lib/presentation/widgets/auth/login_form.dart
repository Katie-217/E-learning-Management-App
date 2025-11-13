import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/users-role.dart';
import 'auth_form_widgets.dart';
import '../../screens/instructor/instructor_dashboard.dart';
import '../../widgets/common/main_shell.dart';
import 'package:elearning_management_app/data/repositories/auth/auth_session_manager.dart';

class LoginForm extends StatefulWidget {
  final UserRole role;

  const LoginForm({super.key, required this.role});

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
      final usernameInput = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userDoc = await _findUserByUsername(usernameInput);
      if (userDoc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy username trong hệ thống.')), 
        );
        return;
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userDoc['email'] as String,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Không tìm thấy người dùng');
      }

      final role = (userDoc['role'] as String?)?.toLowerCase();
      if (role == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tài khoản chưa được gán role.')), 
        );
        return;
      }

      await AuthSessionManager.saveSession(role: role);

      if (!mounted) return;
      if (role == 'instructor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InstructorDashboard()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Lỗi đăng nhập';
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy tài khoản trong hệ thống';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng nhập: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _findUserByUsername(String username) async {
    try {
      final trimmed = username.trim().toLowerCase();
      final query = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final match = query.docs.firstWhere(
        (doc) {
          final data = doc.data();
          final uname = (data['username'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final email = (data['email'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return uname == trimmed || email == trimmed;
        },
        orElse: () => null,
      );

      if (match == null) {
        return null;
      }

      return {...match.data(), 'uid': match.id};
    } catch (_) {
      return null;
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
              hintText: 'Username',
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập username';
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
          ],
        ),
      ),
    );
  }
}


