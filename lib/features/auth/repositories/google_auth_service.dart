// ========================================
// FILE: google_auth_service.dart
// MÔ TẢ: Service xử lý đăng nhập bằng Google
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ========================================
// CLASS: GoogleAuthService
// MÔ TẢ: Service chính cho việc xác thực Google
// ========================================
class GoogleAuthService {
  // ========================================
  // CONSTRUCTOR: Private constructor
  // MÔ TẢ: Singleton pattern cho GoogleAuthService
  // ========================================
  GoogleAuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ========================================
  // INSTANCE: Singleton instance
  // MÔ TẢ: Instance duy nhất của GoogleAuthService
  // ========================================


  // ========================================
  // GETTER: instance
  // MÔ TẢ: Truy cập instance singleton
  // ========================================


  // ========================================
  // HÀM: signInWithGoogle()
  // MÔ TẢ: Xử lý đăng nhập bằng Google
  // ========================================
  Future<User?> signInWithGoogle() async {
    try {
      // Đăng xuất trước để ép Google hiển thị danh sách tài khoản mỗi lần chọn
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        print(
            " Email đã tồn tại với phương thức khác. Cần đăng nhập bằng Email/Password trước rồi link Google.");
      }
      rethrow;
    }
  }

    // Liên kết Google với tài khoản hiện tại (nếu đăng nhập Email/Password trước đó)
    Future<void> linkGoogleAccount() async {
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;

        final GoogleSignInAuthentication googleAuth = await googleUser
            .authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.currentUser?.linkWithCredential(credential);

        print("✅ Google account linked successfully!");
      } catch (e) {
        print("❌ Error linking Google account: $e");
      }
    }


    // ========================================
    // HÀM: signOut()
    // MÔ TẢ: Đăng xuất khỏi Google
    // ========================================
    Future<void> signOut() async {
      try {
        // TODO: Implement Google Sign-Out logic here
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Google sign out error: $e');
      }
    }


  // ========================================
  // HÀM: isSignedIn()
  // MÔ TẢ: Kiểm tra xem người dùng đã đăng nhập Google chưa
  // ========================================
  Future<bool> isSignedIn() async {
    // TODO: Implement check if user is signed in
    return false;
  }
}

// ========================================
// CLASS: GoogleUserInfo
// MÔ TẢ: Thông tin người dùng từ Google
// ========================================
class GoogleUserInfo {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  const GoogleUserInfo({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  // ========================================
  // HÀM: toMap()
  // MÔ TẢ: Chuyển đổi thành Map để lưu trữ
  // ========================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  // ========================================
  // HÀM: fromMap()
  // MÔ TẢ: Tạo từ Map
  // ========================================
  factory GoogleUserInfo.fromMap(Map<String, dynamic> map) {
    return GoogleUserInfo(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }
}

// ========================================
// CLASS: GoogleSignInResult
// MÔ TẢ: Kết quả của quá trình đăng nhập Google
// ========================================
class GoogleSignInResult {
  final bool isSuccess;
  final GoogleUserInfo? user;
  final String? errorMessage;

  const GoogleSignInResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  // ========================================
  // FACTORY: success()
  // MÔ TẢ: Tạo kết quả thành công
  // ========================================
  factory GoogleSignInResult.success(GoogleUserInfo user) {
    return GoogleSignInResult._(
      isSuccess: true,
      user: user,
    );
  }

  // ========================================
  // FACTORY: error()
  // MÔ TẢ: Tạo kết quả lỗi
  // ========================================
  factory GoogleSignInResult.error(String message) {
    return GoogleSignInResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}









