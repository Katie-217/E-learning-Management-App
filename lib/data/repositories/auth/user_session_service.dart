// ========================================
// FILE: user_session_service.dart
// MÔ TẢ: Service cho SharedPreferences - Clean Architecture Compliant
// QUAN TRỌNG: Chỉ làm việc với SharedPreferences, KHÔNG import Firebase!
// ========================================

import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/user_model.dart';

// ========================================
// CLASS: UserSessionService
// MÔ TẢ: Quản lý session với SharedPreferences - Clean Architecture
// ========================================
class UserSessionService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';
  static const String _userUidKey = 'user_uid';
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';

  // ========================================
  // HÀM: saveUserSession - Nhận UserModel
  // MÔ TẢ: Lưu session từ UserModel vào SharedPreferences
  // ========================================
  static Future<void> saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, user.email);
      await prefs.setString(_userDisplayNameKey, user.displayName);
      await prefs.setString(_userUidKey, user.uid);
      await prefs.setString(_userRoleKey, user.role.name);
      await prefs.setString(_userNameKey, user.name);
    } catch (e) {
      // Handle error silently
    }
  }

  // ========================================
  // HÀM: isUserLoggedIn
  // MÔ TẢ: Kiểm tra có user đã đăng nhập không
  // ========================================
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // HÀM: getUserSessionData - Trả về Map cho compatibility
  // MÔ TẢ: Lấy thông tin session từ SharedPreferences
  // ========================================
  static Future<Map<String, String>?> getUserSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) return null;

      return {
        'uid': prefs.getString(_userUidKey) ?? '',
        'email': prefs.getString(_userEmailKey) ?? '',
        'displayName': prefs.getString(_userDisplayNameKey) ?? '',
        'name': prefs.getString(_userNameKey) ?? '',
        'role': prefs.getString(_userRoleKey) ?? 'student',
      };
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // HÀM: clearUserSession
  // MÔ TẢ: Xóa tất cả session data khỏi SharedPreferences
  // ========================================
  static Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userDisplayNameKey);
      await prefs.remove(_userUidKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userNameKey);
    } catch (e) {
      // Handle error silently
    }
  }

  // ========================================
  // HÀM: hasValidSession
  // MÔ TẢ: Kiểm tra có session hợp lệ không (chỉ SharedPreferences)
  // ========================================
  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final uid = prefs.getString(_userUidKey) ?? '';

      return isLoggedIn && uid.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // HÀM: getStoredUserId
  // MÔ TẢ: Lấy nhanh user ID từ SharedPreferences
  // ========================================
  static Future<String?> getStoredUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userUidKey);
    } catch (e) {
      return null;
    }
  }
}
