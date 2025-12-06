import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/controllers/chat/chat_providers.dart';

/// ✅ Wrapper kiểm tra auth state trước khi vào app
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // ✅ Đợi auth provider check session
    final auth = ref.read(authProvider);
    await auth.checkAuthState();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    // 1. ⏳ Chờ khởi tạo hoặc đang loading
    if (!_isInitialized || auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(height: 16),
              Text(
                'Đang tải...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // 2. ❌ Chưa đăng nhập
    if (!auth.isAuthenticated || auth.currentUser == null) {
      return const LoginScreen();
    }

    // 3. ✅ Đã đăng nhập - Route theo role
    final user = auth.currentUser!;
    
    if (user.isInstructor) {
      return const InstructorMainScreen();
    } else {
      return const StudentMainScreen();
    }
  }
}

// ========================================
// Placeholder Screens (Thay bằng screens thật của bạn)
// ========================================

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: const Center(
        child: Text(
          'Login Screen\n(Replace with your actual LoginPage)',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class InstructorMainScreen extends StatelessWidget {
  const InstructorMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: const Center(
        child: Text(
          'Instructor Main Screen\n(Replace with your actual InstructorHomePage)',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class StudentMainScreen extends StatelessWidget {
  const StudentMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF111827),
      ),
      body: const Center(
        child: Text(
          'Student Main Screen\n(Replace with your actual StudentHomePage)',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}