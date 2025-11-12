import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import '../../../providers/auth_provider.dart';
import '../../../../core/config/users-role.dart';

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!value.contains('@')) return 'Please enter a valid email';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // Future<void> signIn(BuildContext context, WidgetRef ref, GlobalKey<FormState> formKey) async {
  //   if (!formKey.currentState!.validate()) return;
  //   _setLoading(true);
  //   try {
  //     await ref.read(authProvider).signIn(
  //           emailController.text.trim(),
  //           passwordController.text.trim(),
  //           context,
  //         );
  //     if (context.mounted) {
  //       Navigator.of(context).pushReplacementNamed('/dashboard');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('$e')),
  //     );
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Future<void> signInWithGoogle(BuildContext context, WidgetRef ref) async {
  //   _setLoading(true);
  //   try {
  //     await ref.read(authProvider).signInWithGoogle(context);
  //     if (context.mounted) {
  //       Navigator.of(context).pushReplacementNamed('/dashboard');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('$e')),
  //     );
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Future<void> resetPassword(BuildContext context, WidgetRef ref) async {
  //   final email = emailController.text.trim();
  //   if (email.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Enter email to reset password')),
  //     );
  //     return;
  //   }
  //   try {
  //     await ref.read(authProvider).resetPassword(email, context);
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('$e')),
  //     );
  //   }
  // }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// final loginControllerProvider = ChangeNotifierProvider<LoginController>((ref) {
//   return LoginController();
// });
