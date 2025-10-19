
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import '../repositories/auth_repository.dart';
// import '../repositories/google_auth_repository.dart';

// final authProvider = Provider<AuthProvider>((ref) {
//   final authRepo = ref.watch(authRepositoryProvider);
//   final googleRepo = ref.watch(googleAuthRepositoryProvider);
//   return AuthProvider(authRepo, googleRepo);
// });

class AuthProvider {
  // final AuthRepository _authRepo;
  // final GoogleAuthRepository _googleRepo;

  // AuthProvider(this._authRepo, this._googleRepo);

  // Future<void> signIn(String email, String password, BuildContext context) async {
  //   await _authRepo.signIn(email, password);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Login successful')),
  //   );
  // }

  // Future<void> signInWithGoogle(BuildContext context) async {
  //   await _googleRepo.signInWithGoogle();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Google login successful')),
  //   );
  // }

  // Future<void> register(String name, String email, String password, BuildContext context, {required UserRole role}) async {
  //   await _authRepo.signUp(name, email, password, role);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Account created')),
  //   );
  // }

  // Future<void> resetPassword(String email, BuildContext context) async {
  //   await _authRepo.sendPasswordReset(email);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('Reset email sent to $email')),
  //   );
  // }

  // Future<void> signOut(BuildContext context) async {
  //   await _authRepo.signOut();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Signed out')),
  //   );
  // }
}
