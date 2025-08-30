import 'package:flutter/material.dart';
import '../../../core/enums/user_role.dart';

class LoginController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 10) {
      return 'Name must be at least 10 characters';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> login(
    BuildContext context,
    UserRole userRole,
    GlobalKey<FormState> formKey,
  ) async {
    if (formKey.currentState!.validate()) {
      _showLoadingDialog(context);

      try {
        await Future.delayed(const Duration(seconds: 2));

        Navigator.pop(context);

        bool loginSuccess = await _authenticateUser(
          nameController.text,
          passwordController.text,
          userRole,
        );

        if (loginSuccess) {
          _navigateToHome(context, userRole);
        } else {
          _showErrorDialog(context, 'Invalid credentials. Please try again.');
        }
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Login failed. Please try again.');
      }
    }
  }

  Future<bool> _authenticateUser(String name, String password, UserRole role) async {
    if (role == UserRole.teacher) {
      return name.toLowerCase() == 'admin' && password == 'admin';
    } else {
      return name.toLowerCase() == 'admin' && password == 'admin';
    }
  }

  void _navigateToHome(BuildContext context, UserRole role) {
    if (role == UserRole.teacher) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TeacherHomeScreen(),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => StudentHomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  void forgotPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text('Password reset functionality will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void navigateToRegister(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(userRole: role),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Logging in...'),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void dispose() {
    nameController.dispose();
    passwordController.dispose();
  }
}

class TeacherHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Color(0xFFEC4899)),
            SizedBox(height: 20),
            Text(
              'Welcome Teacher!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Teacher functionalities will be implemented here.'),
          ],
        ),
      ),
    );
  }
}

class StudentHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 100, color: Color(0xFF3B82F6)),
            SizedBox(height: 20),
            Text(
              'Welcome Student!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Student functionalities will be implemented here.'),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatelessWidget {
  final UserRole userRole;

  const RegisterScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register as ${userRole.displayName}'),
        backgroundColor: userRole.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(userRole.icon, size: 100, color: userRole.primaryColor),
            const SizedBox(height: 20),
            Text(
              'Register as ${userRole.displayName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Registration form will be implemented here.'),
          ],
        ),
      ),
    );
  }
}


