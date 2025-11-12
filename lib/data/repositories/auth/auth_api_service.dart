import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthApiService {
  // Kiểm tra session hiện tại (Firebase-only)
  static Future<Map<String, dynamic>> checkSession() async {
    try {
      print('DEBUG: 🔍 AuthApiService(Firebase) - Checking session...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {
          'success': false,
          'hasSession': false,
          'message': 'No user logged in'
        };
      }
      // Kiểm tra user document trong Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final exists = userDoc.exists;
      return {
        'success': exists,
        'message': exists ? 'Session hợp lệ' : 'User không tồn tại trong hệ thống',
        'hasSession': exists,
        'data': {
          'user': {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          'userData': exists ? userDoc.data() : null,
        }
      };
    } catch (e) {
      print('DEBUG: ❌ Error checking session(Firebase): $e');
      return {
        'success': false,
        'hasSession': false,
        'error': e.toString()
      };
    }
  }

  // "Đăng nhập" (Firebase đã đăng nhập ở client) -> trả thông tin hợp nhất
  static Future<Map<String, dynamic>> login() async {
    try {
      print('DEBUG: 🔑 AuthApiService(Firebase) - Login passthrough...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return { 'success': false, 'message': 'No user logged in' };
      }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return {
        'success': true,
        'message': 'Đăng nhập thành công',
        'data': {
          'user': {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          'userData': userDoc.data(),
          'hasSession': true
        }
      };
    } catch (e) {
      print('DEBUG: ❌ Error login(Firebase): $e');
      return { 'success': false, 'error': e.toString() };
    }
  }

  // Đăng xuất trực tiếp Firebase
  static Future<Map<String, dynamic>> logout() async {
    try {
      print('DEBUG: 🚪 AuthApiService(Firebase) - Logging out...');
      await FirebaseAuth.instance.signOut();
      return {
        'success': true,
        'message': 'Đăng xuất thành công',
        'data': { 'hasSession': false }
      };
    } catch (e) {
      print('DEBUG: ❌ Error logging out(Firebase): $e');
      return { 'success': false, 'error': e.toString() };
    }
  }

  // Lấy thông tin user từ Firebase Auth + Firestore
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      print('DEBUG: 👤 AuthApiService(Firebase) - Getting user info...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return { 'success': false, 'message': 'No user logged in' };
      }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return {
        'success': true,
        'message': 'Lấy thông tin user thành công',
        'data': {
          'user': {
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          },
          'userData': userDoc.data()
        }
      };
    } catch (e) {
      print('DEBUG: ❌ Error getting user info(Firebase): $e');
      return { 'success': false, 'error': e.toString() };
    }
  }

  // Kiểm tra user có tồn tại trong Firestore
  static Future<Map<String, dynamic>> checkUserExists(String uid) async {
    try {
      print('DEBUG: 🔍 AuthApiService(Firebase) - Checking user exists: $uid');
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return {
        'success': true,
        'message': 'Kiểm tra user thành công',
        'data': { 'uid': uid, 'exists': userDoc.exists }
      };
    } catch (e) {
      print('DEBUG: ❌ Error checking user existence(Firebase): $e');
      return { 'success': false, 'error': e.toString() };
    }
  }
}
