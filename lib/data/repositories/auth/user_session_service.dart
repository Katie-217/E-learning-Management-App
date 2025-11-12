import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSessionService {
  static const String _userKey = 'user_session';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';
  static const String _userUidKey = 'user_uid';

  // Save user session to SharedPreferences
  static Future<void> saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, user.email ?? '');
      await prefs.setString(_userDisplayNameKey, user.displayName ?? '');
      await prefs.setString(_userUidKey, user.uid);
      
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get user session from SharedPreferences
  static Future<Map<String, String>?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) return null;
      
      return {
        'email': prefs.getString(_userEmailKey) ?? '',
        'displayName': prefs.getString(_userDisplayNameKey) ?? '',
        'uid': prefs.getString(_userUidKey) ?? '',
      };
      
    } catch (e) {
      return null;
    }
  }

  // Clear user session from SharedPreferences
  static Future<void> clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userDisplayNameKey);
      await prefs.remove(_userUidKey);
      
    } catch (e) {
      // Handle error silently
    }
  }

  // Check and restore user session
  static Future<bool> checkAndRestoreSession() async {
    try {
      // Check current Firebase Auth user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await saveUserSession(currentUser);
        return true;
      }
      
      // Check SharedPreferences session
      final userSession = await getUserSession();
      if (userSession == null) return false;
      
      // Verify user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userSession['uid'])
          .get();
      
      if (!userDoc.exists) {
        await clearUserSession();
        return false;
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserFromFirestore(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (!userDoc.exists) return null;
      
      return userDoc.data();
      
    } catch (e) {
      return null;
    }
  }
}
