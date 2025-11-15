// ========================================
// FILE: enrollment_repository.dart
// MÔ TẢ: Repository quản lý việc ghi danh sinh viên vào khóa học
// Collection: enrollments
// Clean Architecture: Data Layer
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/enrollment_model.dart';

class EnrollmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'enrollments';

  // ========================================
  // HÀM: enrollStudent()
  // MÔ TẢ: Thêm sinh viên vào khóa học (thay thế arrayUnion)
  // ========================================
  Future<String> enrollStudent({
    required String courseId,
    required String userId,
    required String studentName,
    required String studentEmail,
  }) async {
    try {
      // Tạo ID duy nhất theo format courseId_userId
      final enrollmentId = '${courseId}_$userId';

      // Kiểm tra đã tồn tại chưa
      final existingDoc =
          await _firestore.collection(_collection).doc(enrollmentId).get();

      if (existingDoc.exists) {
        final existing =
            EnrollmentModel.fromMap(existingDoc.id, existingDoc.data()!);
        if (existing.status == 'active') {
          throw Exception('Sinh viên đã được ghi danh vào khóa học này');
        }
        // Nếu status là 'dropped', có thể re-enroll
      }

      final enrollment = EnrollmentModel(
        id: enrollmentId,
        courseId: courseId,
        userId: userId,
        studentName: studentName,
        studentEmail: studentEmail,
        enrolledAt: DateTime.now(),
        role: 'student',
        status: 'active',
      );

      await _firestore
          .collection(_collection)
          .doc(enrollmentId)
          .set(enrollment.toMap());

      return enrollmentId;
    } catch (e) {
      throw Exception('Lỗi ghi danh sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: unenrollStudent()
  // MÔ TẢ: Xóa sinh viên khỏi khóa học (thay thế arrayRemove)
  // ========================================
  Future<void> unenrollStudent(String courseId, String userId) async {
    try {
      final enrollmentId = '${courseId}_$userId';

      // Soft delete - chỉ đánh dấu status thành 'dropped'
      await _firestore
          .collection(_collection)
          .doc(enrollmentId)
          .update({'status': 'dropped'});
    } catch (e) {
      throw Exception('Lỗi xóa sinh viên khỏi khóa học: $e');
    }
  }

  // ========================================
  // HÀM: hardDeleteEnrollment()
  // MÔ TẢ: Xóa hoàn toàn enrollment (chỉ dùng khi cần thiết)
  // ========================================
  Future<void> hardDeleteEnrollment(String courseId, String userId) async {
    try {
      final enrollmentId = '${courseId}_$userId';
      await _firestore.collection(_collection).doc(enrollmentId).delete();
    } catch (e) {
      throw Exception('Lỗi xóa enrollment: $e');
    }
  }

  // ========================================
  // HÀM: getStudentsInCourse()
  // MÔ TẢ: Lấy danh sách sinh viên trong khóa học (thay thế course.students)
  // ========================================
  Future<List<EnrollmentModel>> getStudentsInCourse(String courseId) async {
    try {
      print('DEBUG: 🔍 Getting students for courseId: $courseId');

      // Simplified query để avoid composite index requirement
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .get();

      // Filter by role in memory
      final students = querySnapshot.docs
          .map((doc) => EnrollmentModel.fromMap(doc.id, doc.data()))
          .where((enrollment) => enrollment.role == 'student')
          .toList();

      // Sort by enrolledAt in memory
      students.sort((a, b) => a.enrolledAt.compareTo(b.enrolledAt));

      print('DEBUG: ✅ Found ${students.length} students in course');
      return students;
    } catch (e) {
      print('DEBUG: ❌ Error getting students: $e');
      throw Exception('Lỗi lấy danh sách sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: getCoursesOfStudent()
  // MÔ TẢ: Lấy danh sách khóa học của sinh viên (truy vấn ngược)
  // ========================================
  Future<List<EnrollmentModel>> getCoursesOfStudent(String userId) async {
    try {
      print('DEBUG: ========== GET COURSES OF STUDENT ==========');
      print('DEBUG: 🔍 Querying enrollments for userId: $userId');

      // Query chỉ với userId để tránh vấn đề composite index
      // Sau đó filter status và role trong memory
      QuerySnapshot querySnapshot;
      
      try {
        // Query chỉ với userId (không filter status ở Firestore để tránh cần index)
        querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();
        
        print('DEBUG: 📋 Query found ${querySnapshot.docs.length} total enrollment documents');
        
        // Log tất cả documents để debug
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('DEBUG: 📄 Doc ID: ${doc.id}');
          print('DEBUG:    - userId: ${data['userId']}');
          print('DEBUG:    - courseId: ${data['courseId']}');
          print('DEBUG:    - role: ${data['role']}');
          print('DEBUG:    - status: ${data['status']}');
        }
      } catch (e) {
        print('DEBUG: ❌ Error querying enrollments: $e');
        print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
        rethrow;
      }

      // Filter by status and role in memory để đảm bảo lấy đủ
      final allEnrollments = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              return EnrollmentModel.fromMap(doc.id, data);
            } catch (e) {
              print('DEBUG: ⚠️ Error parsing enrollment doc ${doc.id}: $e');
              return null;
            }
          })
          .whereType<EnrollmentModel>()
          .toList();
      
      print('DEBUG: 📊 Parsed ${allEnrollments.length} enrollment models');

      // Filter active student enrollments
      final enrollments = allEnrollments
          .where((enrollment) {
            final isStudent = enrollment.role == 'student';
            final isActive = enrollment.status == 'active';
            if (!isStudent || !isActive) {
              print('DEBUG: ⚠️ Filtered out enrollment: ${enrollment.id} - role: ${enrollment.role}, status: ${enrollment.status}');
            }
            return isStudent && isActive;
          })
          .toList();

      // Sort by enrolledAt in memory
      enrollments.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));

      print('DEBUG: ✅ Final result: ${enrollments.length} active student enrollments');
      
      if (enrollments.isEmpty) {
        print('DEBUG: ⚠️ No active enrollments found for user $userId');
        print('DEBUG: 💡 Check if user has enrollments in Firestore collection: $_collection');
        print('DEBUG: 💡 Query: where userId == $userId');
      } else {
        print('DEBUG: 📚 Course IDs:');
        for (var i = 0; i < enrollments.length; i++) {
          print('DEBUG:   ${i + 1}. ${enrollments[i].courseId}');
        }
      }
      
      print('DEBUG: ===========================================');
      return enrollments;
    } catch (e) {
      print('DEBUG: ❌ Error in getCoursesOfStudent: $e');
      print('DEBUG: ❌ Stack trace: ${StackTrace.current}');
      throw Exception('Lỗi lấy danh sách khóa học của sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: countStudentsInCourse()
  // MÔ TẢ: Đếm số sinh viên trong khóa học (thay thế course.students.length)
  // ========================================
  Future<int> countStudentsInCourse(String courseId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .where('status', isEqualTo: 'active')
          .where('role', isEqualTo: 'student')
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Lỗi đếm sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: isStudentEnrolled()
  // MÔ TẢ: Kiểm tra sinh viên có trong khóa học không (thay thế course.students.contains)
  // ========================================
  Future<bool> isStudentEnrolled(String courseId, String userId) async {
    try {
      final enrollmentId = '${courseId}_$userId';
      final docSnapshot =
          await _firestore.collection(_collection).doc(enrollmentId).get();

      if (!docSnapshot.exists) return false;

      final enrollment =
          EnrollmentModel.fromMap(docSnapshot.id, docSnapshot.data()!);
      return enrollment.status == 'active' && enrollment.role == 'student';
    } catch (e) {
      return false;
    }
  }

  // ========================================
  // HÀM: bulkEnrollStudents()
  // MÔ TẢ: Ghi danh hàng loạt sinh viên (cho CSV import)
  // ========================================
  Future<Map<String, dynamic>> bulkEnrollStudents({
    required String courseId,
    required List<Map<String, String>> students, // [{userId, name, email}, ...]
  }) async {
    try {
      final batch = _firestore.batch();
      final results = <String, String>{}; // enrollmentId -> status

      for (final student in students) {
        final userId = student['userId']!;
        final enrollmentId = '${courseId}_$userId';

        // Kiểm tra trùng lặp
        final existing =
            await _firestore.collection(_collection).doc(enrollmentId).get();

        if (existing.exists) {
          results[enrollmentId] = 'duplicate';
          continue;
        }

        final enrollment = EnrollmentModel(
          id: enrollmentId,
          courseId: courseId,
          userId: userId,
          studentName: student['name'],
          studentEmail: student['email'],
          enrolledAt: DateTime.now(),
          role: 'student',
          status: 'active',
        );

        batch.set(
          _firestore.collection(_collection).doc(enrollmentId),
          enrollment.toMap(),
        );

        results[enrollmentId] = 'success';
      }

      await batch.commit();

      return {
        'total': students.length,
        'successful': results.values.where((v) => v == 'success').length,
        'duplicates': results.values.where((v) => v == 'duplicate').length,
        'details': results,
      };
    } catch (e) {
      throw Exception('Lỗi ghi danh hàng loạt: $e');
    }
  }

  // ========================================
  // HÀM: listenToEnrollmentsInCourse()
  // MÔ TẢ: Stream để theo dõi thay đổi danh sách sinh viên
  // ========================================
  Stream<List<EnrollmentModel>> listenToEnrollmentsInCourse(String courseId) {
    return _firestore
        .collection(_collection)
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: 'active')
        .where('role', isEqualTo: 'student')
        .orderBy('enrolledAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnrollmentModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ========================================
  // HÀM: updateEnrollmentStatus()
  // MÔ TẢ: Cập nhật trạng thái enrollment
  // ========================================
  Future<void> updateEnrollmentStatus(
    String courseId,
    String userId,
    String newStatus,
  ) async {
    try {
      final enrollmentId = '${courseId}_$userId';
      await _firestore
          .collection(_collection)
          .doc(enrollmentId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái enrollment: $e');
    }
  }

  // ========================================
  // HÀM: getEnrollmentStatistics()
  // MÔ TẢ: Thống kê enrollment
  // ========================================
  Future<Map<String, int>> getEnrollmentStatistics(String courseId) async {
    try {
      final allEnrollments = await _firestore
          .collection(_collection)
          .where('courseId', isEqualTo: courseId)
          .where('role', isEqualTo: 'student')
          .get();

      final stats = <String, int>{
        'total': allEnrollments.docs.length,
        'active': 0,
        'dropped': 0,
      };

      for (final doc in allEnrollments.docs) {
        final status = doc.data()['status'] ?? 'active';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Lỗi lấy thống kê enrollment: $e');
    }
  }
}
