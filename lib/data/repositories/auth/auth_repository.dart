import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/config/users-role.dart';

class AuthRepository {
  static AuthRepository? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepository._internal();
  
  static AuthRepository defaultClient() {
    _instance ??= AuthRepository._internal();
    return _instance!;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // Sign up with email and password
  Future<User?> signUp(String name, String email, String password, UserRole role) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);
        
        // Save user data to Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'role': role.name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return credential.user;
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Gửi email đặt lại mật khẩu thất bại: $e');
    }
  }

  // Fetch user role from Firestore
  Future<String?> fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      return null;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

// final authRepositoryProvider = Provider<AuthRepository>((ref) {
//   return AuthRepository.defaultClient();
// });



