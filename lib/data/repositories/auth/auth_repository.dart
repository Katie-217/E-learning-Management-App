// ========================================
// FILE: auth_repository.dart
// MÔ TẢ: Repository duy nhất cho Authentication - Tuân thủ Clean Architecture
// QUAN TRỌNG: File duy nhất được phép import Firebase!
// ========================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/config/users-role.dart';
import '../../../domain/models/user_model.dart';

// ========================================
// CLASS: AuthRepository
// MÔ TẢ: Repository duy nhất cho Authentication - Clean Architecture
// ========================================
class AuthRepository {
  static AuthRepository? _instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepository._internal();

  static AuthRepository defaultClient() {
    _instance ??= AuthRepository._internal();
    return _instance!;
  }

  // ========================================
  // GETTER: currentUserModel - Trả về UserModel thay vì Firebase User
  // ========================================
  Future<UserModel?> get currentUserModel async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // HÀM: signInWithEmailAndPassword - Trả về UserModel
  // MÔ TẢ: Đăng nhập tối ưu và trả về UserModel (gộp từ signInWithRole)
  // ========================================
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print("🔐 Đang xác thực: $email");

      // 1. Đăng nhập Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Đăng nhập thất bại: Không nhận được thông tin user');
      }

      print("✅ Auth thành công, đang lấy user data...");

      // 2. Lấy UserModel từ Firestore ngay lập tức (tối ưu)
      final userDoc =
          await _firestore.collection('users').doc(credential.user!.uid).get();
      if (!userDoc.exists) {
        throw Exception('User không tồn tại trong hệ thống');
      }

      // 3. Cập nhật lastLoginAt (async - không chờ)
      _firestore.collection('users').doc(credential.user!.uid).update({
        'lastLoginAtLocal': DateTime.now().toString(),
      }).catchError((e) => print('Warning: Could not update lastLoginAt: $e'));

      print("✅ Đăng nhập hoàn tất - Role: ${userDoc.data()?['role']}");

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      print("❌ Lỗi đăng nhập: $e");
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // ========================================
  // HÀM: createUserAccount - Trả về UserModel
  // MÔ TẢ: Đăng ký tài khoản mới và trả về UserModel
  // ========================================
  Future<UserModel> createUserAccount(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      // 1. Tạo Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Đăng ký thất bại: Không tạo được tài khoản');
      }

      // 2. Cập nhật displayName
      await credential.user!.updateDisplayName(name);

      // 3. Tạo UserModel
      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        name: name,
        displayName: name,
        role: role,
        photoUrl: null,
        createdAt: DateTime.now(),
        lastLoginAt: null,
        settings: const UserSettings(), // Default settings
        isActive: true,
        isDefault: false,
      );

      // 4. Lưu UserModel vào Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      return userModel;
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  // ========================================
  // HÀM: signOut
  // MÔ TẢ: Đăng xuất người dùng
  // ========================================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Đăng xuất thất bại: $e');
    }
  }

  // ========================================
  // HÀM: sendPasswordResetEmail
  // MÔ TẢ: Gửi email đặt lại mật khẩu
  // ========================================
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Gửi email đặt lại mật khẩu thất bại: $e');
    }
  }

  // ========================================
  // HÀM: getUserById - Trả về UserModel
  // MÔ TẢ: Lấy thông tin user theo uid, trả về UserModel
  // ========================================
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // HÀM: updateUserProfile - Nhận UserModel
  // MÔ TẢ: Cập nhật thông tin user bằng UserModel
  // ========================================
  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toFirestore());

      // Trả về UserModel sau khi cập nhật
      return updatedUser;
    } catch (e) {
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }

  // ========================================
  // HÀM: checkUserSession - Trả về UserModel
  // MÔ TẢ: Kiểm tra session hiện tại và trả về UserModel
  // ========================================
  Future<UserModel?> checkUserSession() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // Kiểm tra user document trong Firestore
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) return null;

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // STREAM: userModelStream - Stream UserModel thay vì Firebase User
  // MÔ TẢ: Stream theo dõi thay đổi auth state, trả về UserModel
  // ========================================
  Stream<UserModel?> get userModelStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!userDoc.exists) return null;

        return UserModel.fromFirestore(userDoc);
      } catch (e) {
        return null;
      }
    });
  }

  // ========================================
  // HÀM: signInAnonymously - Cho testing
  // MÔ TẢ: Đăng nhập ẩn danh cho việc test
  // ========================================
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user;
    } catch (e) {
      throw Exception('Đăng nhập ẩn danh thất bại: $e');
    }
  }

  // ========================================
  // GETTER: isUserLoggedIn
  // MÔ TẢ: Kiểm tra nhanh có user đang đăng nhập không
  // ========================================
  bool get isUserLoggedIn => _auth.currentUser != null;

  // ========================================
  // METHOD: getCurrentUserId
  // MÔ TẢ: Lấy user ID hiện tại (cho CourseRepository)
  // ========================================
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository.defaultClient();
});
