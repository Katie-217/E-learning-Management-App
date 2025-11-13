import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearning_management_app/domain/models/course_model.dart';

class FirestoreCourseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'course_of_study';

  // Lấy danh sách khóa học của user hiện tại
  static Future<List<CourseModel>> getCourses() async {
    try {
      print('DEBUG: ========== FIRESTORE COURSE SERVICE ==========');

      // Kiểm tra user đăng nhập
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: ❌ No user logged in');
        return [];
      }

      print('DEBUG: ✅ User logged in: ${user.uid}');
      print('DEBUG: 📧 Email: ${user.email}');
      print('DEBUG: 👤 Display name: ${user.displayName ?? 'N/A'}');

      // Lấy tất cả khóa học từ Firestore
      print('DEBUG: 📥 Fetching courses from Firestore...');
      final QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();

      print('DEBUG: 📊 Found ${snapshot.docs.length} total courses');

      if (snapshot.docs.isEmpty) {
        print('DEBUG: ⚠️ No courses found in Firestore');
        return [];
      }

      // Lọc khóa học mà user tham gia
      final userCourses = <CourseModel>[];
      print('DEBUG: 🔍 Filtering courses for user ${user.uid}...');

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        final students = data['students'] as List<dynamic>? ?? [];
        final courseName = data['name'] ?? 'Unknown';
        final courseCode = data['code'] ?? 'Unknown';

        print('DEBUG: 📚 Course ${i + 1}: $courseName ($courseCode)');
        print('DEBUG:   👥 Students: ${students.length} students');
        print('DEBUG:   🆔 Student IDs: ${students.join(', ')}');
        print('DEBUG:   🔍 Looking for: ${user.uid}');

        // Kiểm tra user ID có trong danh sách students không
        if (students.contains(user.uid)) {
          userCourses.add(CourseModel.fromFirestore(doc));
          print('DEBUG:   ✅ User IS enrolled in: $courseName');
        } else {
          print('DEBUG:   ❌ User NOT enrolled in: $courseName');
        }
        print('DEBUG:   ---');
      }

      print('DEBUG: 🎯 Result: User enrolled in ${userCourses.length} courses');
      print('DEBUG: ================================================');
      return userCourses;
    } catch (e) {
      print('DEBUG: ❌ Error fetching courses: $e');
      return [];
    }
  }

  // Lấy khóa học theo ID
  static Future<CourseModel?> getCourseById(String id) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return CourseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching course by ID from Firestore: $e');
      return null;
    }
  }

  // Lấy khóa học theo học kì
  static Future<List<CourseModel>> getCoursesBySemester(String semester) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('semester', isEqualTo: semester)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching courses by semester from Firestore: $e');
      // Trả về danh sách trống nếu có lỗi
      return [];
    }
  }

  // Lấy khóa học theo trạng thái
  static Future<List<CourseModel>> getCoursesByStatus(String status) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching courses by status from Firestore: $e');
      // Trả về danh sách trống nếu có lỗi
      return [];
    }
  }

  // Tạo khóa học mới
  static Future<CourseModel?> createCourse(CourseModel course) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add({
        ...course.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Lấy dữ liệu vừa tạo
      final doc = await docRef.get();
      return CourseModel.fromFirestore(doc);
    } catch (e) {
      print('Error creating course in Firestore: $e');
      return null;
    }
  }

  // Cập nhật khóa học
  static Future<CourseModel?> updateCourse(
      String id, CourseModel course) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        ...course.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Lấy dữ liệu vừa cập nhật
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      return CourseModel.fromFirestore(doc);
    } catch (e) {
      print('Error updating course in Firestore: $e');
      return null;
    }
  }

  // Xóa khóa học
  static Future<bool> deleteCourse(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting course from Firestore: $e');
      return false;
    }
  }

  // Lắng nghe thay đổi real-time
  static Stream<List<CourseModel>> getCoursesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList());
  }

  // Lắng nghe thay đổi theo học kì
  static Stream<List<CourseModel>> getCoursesBySemesterStream(String semester) {
    return _firestore
        .collection(_collectionName)
        .where('semester', isEqualTo: semester)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList());
  }

  // Lắng nghe thay đổi theo trạng thái
  static Stream<List<CourseModel>> getCoursesByStatusStream(String status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CourseModel.fromFirestore(doc))
            .toList());
  }
}
