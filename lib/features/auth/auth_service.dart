// ========================================
// FILE: auth_service.dart
// MÔ TẢ: Service xử lý xác thực người dùng
// ========================================

import 'package:dio/dio.dart';
import '../../services/api/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/enums/user_role.dart';
import 'google_auth_service.dart';
// ========================================
// CLASS: AuthService
// MÔ TẢ: Service chính cho việc xác thực và đăng nhập
// ========================================



class AuthService {
  AuthService(this._dio);

  final Dio _dio;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleAuthService _googleAuthService =  GoogleAuthService();

String getLocalDateTime() {
  final now = DateTime.now(); // theo giờ local của device
  return DateFormat("yyyy-MM-dd HH:mm:ss").format(now);
}
  // ========================================
  // HÀM: defaultClient()
  // MÔ TẢ: Factory constructor tạo instance mặc định
  // ========================================
  factory AuthService.defaultClient() => AuthService(ApiClient.instance.client);

 
  // Đăng ký tài khoản mới
 Future<User?> signUp(String name, String email, String password, UserRole role) async {
  try {
    // Tạo user trong Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Lưu thông tin user vào Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
        'uid': userCredential.user!.uid,
        'createdAtLocal': getLocalDateTime(),
        'email': email,
        'role': role.name, 
        'name': name,
        'settings': {
          'language': 'vi',
          'theme': 'light',
          'status': 'active',
        },
        });

    print("✅ User registered and saved to Firestore successfully");
    return userCredential.user;
  } catch (e) {
    print("❌ Error in signUp: $e");
    print("Error type: ${e.runtimeType}");
    return null;
  }
}


  // Đăng nhập Email/Password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error in signIn: $e");
      return null;
    }
  }

  // Đăng nhập với Google
  Future<User?> signInWithGoogle() async {
    try {
      User? user;
      if (kIsWeb) {
        try {
          final googleProvider = GoogleAuthProvider();
          // Hiện hộp chọn tài khoản trên web mỗi lần
          googleProvider.setCustomParameters({'prompt': 'select_account'});
          final userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
          user = userCredential.user;
        } catch (e) {
          print("Google Sign-In Error (web popup): $e");
          return null;
        }
      } else {
        user = await _googleAuthService.signInWithGoogle();
      }

      if (user != null) {
        final DocumentReference<Map<String, dynamic>> userDoc =
            _firestore.collection('users').doc(user.uid);
        final snapshot = await userDoc.get();

        if (!snapshot.exists) {
          final String roleToPersist = 'student';
          await userDoc.set({
            'uid': user.uid,
            'createdAtLocal': getLocalDateTime(),
            'email': user.email,
            'role': roleToPersist,
            'name': user.displayName ?? '',
            'photoUrl': user.photoURL,
            'settings': {
              'language': 'vi',
              'theme': 'light',
              'status': 'active',
            },
          });
        } else {
          // Giữ nguyên role đã có khi người dùng đăng ký trước đó
          final existingData = snapshot.data();
          final existingRole = existingData != null ? existingData['role'] : null;
          await userDoc.set({
            'email': user.email,
            'name': user.displayName ?? '',
            'photoUrl': user.photoURL,
            'lastLoginAtLocal': getLocalDateTime(),
            if (existingRole != null) 'role': existingRole,
          }, SetOptions(merge: true));
        }
      }

      // Nếu có user hiện tại (đăng nhập email/password) thì liên kết Google vào
      if (_auth.currentUser != null) {
        await _googleAuthService.linkGoogleAccount();
      }

      return user;
    } catch (e) {
      print("Lỗi Google Sign-In: $e");
      return null;
    }
  }


  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy role người dùng từ Firestore
  Future<String?> fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      return data != null ? data['role'] as String? : null;
    } catch (e) {
      print("Error fetching user role: $e");
      return null;
    }
  }

  // Kiểm tra role của user và điều hướng
  // Future<void> checkUserRole(BuildContext context) async {
  //   String uid = FirebaseAuth.instance.currentUser!.uid;

  //   DocumentSnapshot userDoc =
  //       await FirebaseFirestore.instance.collection('users').doc(uid).get();

  //   String role = userDoc['role'];

  //   if (role == 'teacher') {
  //     // chuyển tới dashboard giáo viên
  //     print("Go to Teacher Dashboard");
  //     Navigator.of(context).pushReplacementNamed('/teacher-dashboard');
  //   } else {
  //     // chuyển tới dashboard học sinh
  //     print("Go to Student Dashboard");
  //     Navigator.of(context).pushReplacementNamed('/student-dashboard');
  //   }
  // }
}












