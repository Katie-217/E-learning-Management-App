import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AuthApiService {
  static const String _baseUrl = 'http://localhost:3000/api/auth';
  
  // Kiểm tra session hiện tại
  static Future<Map<String, dynamic>> checkSession() async {
    try {
      print('DEBUG: 🔍 AuthApiService - Checking session...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: ❌ No Firebase user found');
        return {
          'success': false,
          'hasSession': false,
          'message': 'No user logged in'
        };
      }
      
      // Lấy ID token
      final idToken = await user.getIdToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/check-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      
      final data = json.decode(response.body);
      print('DEBUG: 📊 Session check response: $data');
      
      return data;
      
    } catch (e) {
      print('DEBUG: ❌ Error checking session: $e');
      return {
        'success': false,
        'hasSession': false,
        'error': e.toString()
      };
    }
  }
  
  // Đăng nhập và tạo session
  static Future<Map<String, dynamic>> login() async {
    try {
      print('DEBUG: 🔑 AuthApiService - Logging in...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: ❌ No Firebase user found');
        return {
          'success': false,
          'message': 'No user logged in'
        };
      }
      
      // Lấy ID token
      final idToken = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      
      final data = json.decode(response.body);
      print('DEBUG: 📊 Login response: $data');
      
      return data;
      
    } catch (e) {
      print('DEBUG: ❌ Error logging in: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  // Đăng xuất
  static Future<Map<String, dynamic>> logout() async {
    try {
      print('DEBUG: 🚪 AuthApiService - Logging out...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: ⚠️ No user to logout');
        return {
          'success': true,
          'message': 'No user to logout'
        };
      }
      
      // Lấy ID token
      final idToken = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      
      final data = json.decode(response.body);
      print('DEBUG: 📊 Logout response: $data');
      
      return data;
      
    } catch (e) {
      print('DEBUG: ❌ Error logging out: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  // Lấy thông tin user
  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      print('DEBUG: 👤 AuthApiService - Getting user info...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: ❌ No Firebase user found');
        return {
          'success': false,
          'message': 'No user logged in'
        };
      }
      
      // Lấy ID token
      final idToken = await user.getIdToken();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );
      
      final data = json.decode(response.body);
      print('DEBUG: 📊 User info response: $data');
      
      return data;
      
    } catch (e) {
      print('DEBUG: ❌ Error getting user info: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  // Kiểm tra user có tồn tại không
  static Future<Map<String, dynamic>> checkUserExists(String uid) async {
    try {
      print('DEBUG: 🔍 AuthApiService - Checking if user exists: $uid');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/user-exists/$uid'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      final data = json.decode(response.body);
      print('DEBUG: 📊 User exists response: $data');
      
      return data;
      
    } catch (e) {
      print('DEBUG: ❌ Error checking user existence: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}
