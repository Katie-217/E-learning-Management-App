import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Đăng nhập với email/password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('DEBUG: User signed in successfully: ${credential.user?.email}');
      return credential.user;
    } catch (e) {
      print('DEBUG: Sign in failed: $e');
      return null;
    }
  }

  // Đăng nhập ẩn danh (để test)
  static Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      print('DEBUG: Anonymous sign in successful: ${credential.user?.uid}');
      return credential.user;
    } catch (e) {
      print('DEBUG: Anonymous sign in failed: $e');
      return null;
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('DEBUG: User signed out successfully');
    } catch (e) {
      print('DEBUG: Sign out failed: $e');
    }
  }

  // Kiểm tra user hiện tại
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Tạo collection courses với dữ liệu mẫu
  static Future<void> createSampleCourses() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('DEBUG: No user logged in, cannot create sample data');
        return;
      }

      print('DEBUG: Creating sample courses for user: ${user.uid}');
      
      // Tạo dữ liệu mẫu với students field chứa user ID
      final sampleCourses = [
        {
          'code': 'IT4409',
          'name': 'Web Programming & Applications',
          'instructor': 'Dr. Nguyen Van A',
          'semester': 'Spring 2025',
          'sessions': 15,
          'students': [user.uid, 'student2', 'student3'], // Danh sách student IDs
          'studentCount': 3, // Số lượng students
          'group': 'Group 1',
          'gradient': '#FF0000,#00FF00',
          'progress': 65,
          'description': 'Learn modern web development with React, Node.js, and databases',
          'credits': 3,
          'imageUrl': 'https://picsum.photos/400/200?random=1',
          'totalStudents': 3,
          'startDate': Timestamp.fromDate(DateTime(2025, 1, 15)),
          'endDate': Timestamp.fromDate(DateTime(2025, 5, 15)),
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
        },
        {
          'code': 'IT3100',
          'name': 'Database Management Systems',
          'instructor': 'Dr. Tran Thi B',
          'semester': 'Spring 2025',
          'sessions': 15,
          'students': [user.uid, 'student4', 'student5'], // Danh sách student IDs
          'studentCount': 3, // Số lượng students
          'group': 'Group 2',
          'gradient': '#800080,#FFC0CB',
          'progress': 45,
          'description': 'Database design, SQL, and database administration',
          'credits': 3,
          'imageUrl': 'https://picsum.photos/400/200?random=2',
          'totalStudents': 3,
          'startDate': Timestamp.fromDate(DateTime(2025, 1, 15)),
          'endDate': Timestamp.fromDate(DateTime(2025, 5, 15)),
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
        },
        {
          'code': 'IT4788',
          'name': 'Mobile Application Development',
          'instructor': 'Dr. Le Van C',
          'semester': 'Spring 2025',
          'sessions': 15,
          'students': ['student6', 'student7'], // Không có user hiện tại
          'studentCount': 2,
          'group': 'Group 1',
          'gradient': '#00FF00,#00FFFF',
          'progress': 80,
          'description': 'Cross-platform mobile development with Flutter',
          'credits': 3,
          'imageUrl': 'https://picsum.photos/400/200?random=3',
          'totalStudents': 2,
          'startDate': Timestamp.fromDate(DateTime(2025, 1, 15)),
          'endDate': Timestamp.fromDate(DateTime(2025, 5, 15)),
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': user.uid,
        },
      ];

      // Thêm dữ liệu vào Firestore
      final batch = _firestore.batch();
      for (final course in sampleCourses) {
        final docRef = _firestore.collection('courses').doc();
        batch.set(docRef, course);
      }
      
      await batch.commit();
      print('DEBUG: Sample courses created successfully');
      print('DEBUG: User ${user.uid} is enrolled in 2 courses');
      
    } catch (e) {
      print('DEBUG: Error creating sample courses: $e');
    }
  }

  // Kiểm tra Firestore rules
  static Future<void> testFirestoreRules() async {
    try {
      final user = _auth.currentUser;
      print('DEBUG: Testing Firestore rules...');
      print('DEBUG: Current user: ${user?.email ?? "Anonymous"}');
      print('DEBUG: User UID: ${user?.uid ?? "None"}');
      
      // Test read
      print('DEBUG: Testing read permission...');
      final snapshot = await _firestore.collection('courses').limit(1).get();
      print('DEBUG: Read test - Found ${snapshot.docs.length} documents');
      
      // Test write
      if (user != null) {
        print('DEBUG: Testing write permission...');
        await _firestore.collection('test').doc('permission_test').set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
          'test': true,
        });
        print('DEBUG: Write test - Success');
        
        // Clean up
        await _firestore.collection('test').doc('permission_test').delete();
        print('DEBUG: Cleanup - Success');
      }
      
    } catch (e) {
      print('DEBUG: Firestore rules test failed: $e');
    }
  }
}
