import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseConnectionService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kiểm tra kết nối Firebase
  static Future<bool> checkConnection() async {
    try {
      // Kiểm tra Firebase Auth
      final user = _auth.currentUser;
      print('DEBUG: Firebase Auth - User: ${user?.email ?? "Not logged in"}');
      
      // Kiểm tra Firestore connection
      await _firestore.collection('test').limit(1).get();
      print('DEBUG: Firestore connection successful');
      
      return true;
    } catch (e) {
      print('DEBUG: Firebase connection failed: $e');
      return false;
    }
  }

  // Kiểm tra quyền truy cập Firestore
  static Future<bool> checkFirestorePermissions() async {
    try {
      // Thử đọc một document test
      await _firestore.collection('courses').limit(1).get();
      print('DEBUG: Firestore permissions OK');
      return true;
    } catch (e) {
      print('DEBUG: Firestore permissions error: $e');
      return false;
    }
  }

  // Lấy thông tin user hiện tại
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in');
        return null;
      }

      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
      };
    } catch (e) {
      print('DEBUG: Error getting user info: $e');
      return null;
    }
  }

  // Kiểm tra Firestore rules
  static Future<void> testFirestoreRules() async {
    try {
      print('DEBUG: Testing Firestore rules...');
      
      // Test read permission
      final snapshot = await _firestore.collection('courses').limit(1).get();
      print('DEBUG: Read test - Found ${snapshot.docs.length} documents');
      
      // Test write permission (nếu có user đăng nhập)
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('test').doc('permission_test').set({
            'timestamp': FieldValue.serverTimestamp(),
            'userId': user.uid,
          });
          print('DEBUG: Write test - Success');
          
          // Clean up test document
          await _firestore.collection('test').doc('permission_test').delete();
          print('DEBUG: Cleanup - Success');
        } catch (e) {
          print('DEBUG: Write test failed: $e');
        }
      } else {
        print('DEBUG: No user logged in, skipping write test');
      }
      
    } catch (e) {
      print('DEBUG: Firestore rules test failed: $e');
    }
  }
}
