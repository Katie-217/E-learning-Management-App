// ========================================
// FILE: student_repository.dart (FIXED)
// MÔ TẢ: Repository sinh viên - Tránh cần index composite
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/student_model.dart';

class StudentRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // ========================================
  // HÀM: getAllStudents() - FIXED VERSION
  // MÔ TẢ: Lấy tất cả sinh viên (tránh composite index)
  // Chiến lược: Query toàn bộ, filter trên client
  // ========================================
  static Future<List<StudentModel>> getAllStudents() async {
    try {
      print('DEBUG: 📚 Lấy tất cả sinh viên (client-side filtering)');

      // ❌ CŨ (gây lỗi index):
      // final querySnapshot = await _firestore
      //     .collection(_collection)
      //     .where('role', isEqualTo: 'student')
      //     .orderBy('name')
      //     .get();

      // ✅ MỚI (tránh index):
      // Bước 1: Lấy toàn bộ documents từ collection
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      print('DEBUG: 📊 Tổng documents: ${querySnapshot.docs.length}');

      // Bước 2: Filter và sort trên client (không cần index)
      final students = querySnapshot.docs
          .map((doc) {
            try {
              return StudentModel.fromFirestore(doc);
            } catch (e) {
              print('DEBUG: ⚠️ Lỗi parse document ${doc.id}: $e');
              return null;
            }
          })
          .where((s) => s != null && s.role == 'student') // Filter trên client
          .cast<StudentModel>()
          .toList();

      // Sort theo tên trên client
      students.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: ✅ Lấy ${students.length} sinh viên thành công');
      return students;
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách sinh viên: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getStudentsByCourse() - FIXED
  // MÔ TẢ: Lấy sinh viên theo course (tránh index)
  // ========================================
  static Future<List<StudentModel>> getStudentsByCourse(
    String courseId,
  ) async {
    try {
      print('DEBUG: 📚 Lấy sinh viên của course: $courseId');

      // ✅ Chiến lược: Lấy toàn bộ, filter trên client
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final students = querySnapshot.docs
          .map((doc) {
            try {
              return StudentModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .where((s) =>
              s != null &&
              s.role == 'student' &&
              s.courseIds.contains(courseId))
          .cast<StudentModel>()
          .toList();

      students.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: ✅ Lấy ${students.length} sinh viên thành công');
      return students;
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: getStudentsByGroup() - FIXED
  // MÔ TẢ: Lấy sinh viên theo group (tránh index)
  // ========================================
  static Future<List<StudentModel>> getStudentsByGroup(
    String groupId,
  ) async {
    try {
      print('DEBUG: 👥 Lấy sinh viên của group: $groupId');

      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final students = querySnapshot.docs
          .map((doc) {
            try {
              return StudentModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .where((s) =>
              s != null &&
              s.role == 'student' &&
              s.groupIds.contains(groupId))
          .cast<StudentModel>()
          .toList();

      students.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: ✅ Lấy ${students.length} sinh viên thành công');
      return students;
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: searchStudents() - FIXED
  // MÔ TẢ: Tìm kiếm sinh viên (tránh index)
  // ========================================
  static Future<List<StudentModel>> searchStudents(String query) async {
    try {
      print('DEBUG: 🔎 Tìm kiếm: $query');

      if (query.isEmpty) {
        return await getAllStudents();
      }

      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final queryLower = query.toLowerCase();
      final students = querySnapshot.docs
          .map((doc) {
            try {
              return StudentModel.fromFirestore(doc);
            } catch (e) {
              return null;
            }
          })
          .where((s) =>
              s != null &&
              s.role == 'student' &&
              (s.name.toLowerCase().contains(queryLower) ||
                  (s.studentCode?.toLowerCase().contains(queryLower) ?? false) ||
                  s.email.toLowerCase().contains(queryLower)))
          .cast<StudentModel>()
          .toList();

      students.sort((a, b) => a.name.compareTo(b.name));

      print('DEBUG: ✅ Tìm thấy ${students.length} sinh viên');
      return students;
    } catch (e) {
      print('DEBUG: ❌ Lỗi tìm kiếm: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: createStudent()
  // MÔ TẢ: Tạo sinh viên mới
  // ========================================
  static Future<String> createStudent(StudentModel student) async {
    try {
      print('DEBUG: 📝 Tạo sinh viên: ${student.name}');

      await _firestore.collection(_collection).doc(student.uid).set(
            student.toFirestore(),
            SetOptions(merge: true),
          );

      print('DEBUG: ✅ Sinh viên tạo thành công: ${student.uid}');
      return student.uid;
    } catch (e) {
      print('DEBUG: ❌ Lỗi tạo sinh viên: $e');
      throw Exception('Lỗi tạo sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: getStudentById()
  // MÔ TẢ: Lấy sinh viên theo ID
  // ========================================
  static Future<StudentModel?> getStudentById(String studentUid) async {
    try {
      print('DEBUG: 🔍 Lấy sinh viên: $studentUid');

      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(studentUid)
          .get();

      if (!docSnapshot.exists) {
        print('DEBUG: ⚠️ Sinh viên không tìm thấy');
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      if (data['role'] != 'student') {
        print('DEBUG: ⚠️ User không phải sinh viên, role: ${data['role']}');
        return null;
      }

      return StudentModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy sinh viên: $e');
      throw Exception('Lỗi lấy sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: getStudentsByIds()
  // MÔ TẢ: Lấy nhiều sinh viên (tránh index)
  // ========================================
  static Future<List<StudentModel>> getStudentsByIds(
    List<String> studentUids,
  ) async {
    try {
      if (studentUids.isEmpty) return [];

      print('DEBUG: 📚 Lấy ${studentUids.length} sinh viên');

      // ✅ Lấy từng document riêng (không cần index)
      final students = <StudentModel>[];
      for (final uid in studentUids) {
        final doc = await _firestore
            .collection(_collection)
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['role'] == 'student') {
            students.add(StudentModel.fromFirestore(doc));
          }
        }
      }

      print('DEBUG: ✅ Lấy ${students.length} sinh viên thành công');
      return students;
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy danh sách: $e');
      return [];
    }
  }

  // ========================================
  // HÀM: updateStudent()
  // MÔ TẢ: Cập nhật thông tin sinh viên
  // ========================================
  static Future<void> updateStudent(StudentModel student) async {
    try {
      print('DEBUG: ✏️ Cập nhật sinh viên: ${student.uid}');

      await _firestore
          .collection(_collection)
          .doc(student.uid)
          .update(student.toFirestore());

      print('DEBUG: ✅ Cập nhật thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi cập nhật: $e');
      throw Exception('Lỗi cập nhật sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: updateStudentProfile()
  // MÔ TẢ: Cập nhật profile sinh viên
  // ========================================
  static Future<void> updateStudentProfile(
    String studentUid, {
    String? name,
    String? phone,
    String? department,
    String? studentCode,
  }) async {
    try {
      print('DEBUG: 📝 Cập nhật profile sinh viên: $studentUid');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (department != null) updates['department'] = department;
      if (studentCode != null) updates['studentCode'] = studentCode;

      await _firestore
          .collection(_collection)
          .doc(studentUid)
          .update(updates);

      print('DEBUG: ✅ Cập nhật thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi cập nhật: $e');
      throw Exception('Lỗi cập nhật: $e');
    }
  }

  // ========================================
  // HÀM: deleteStudent()
  // MÔ TẢ: Xóa sinh viên (set inactive)
  // ========================================
  static Future<void> deleteStudent(String studentUid) async {
    try {
      print('DEBUG: 🗑️ Xóa sinh viên: $studentUid');

      await _firestore.collection(_collection).doc(studentUid).update({
        'isActive': false,
        'settings': {
          'status': 'inactive',
        }
      });

      print('DEBUG: ✅ Xóa thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi xóa: $e');
      throw Exception('Lỗi xóa sinh viên: $e');
    }
  }

  // ========================================
  // HÀM: enrollStudentToCourse()
  // MÔ TẢ: Thêm sinh viên vào course
  // ========================================
  static Future<void> enrollStudentToCourse(
    String studentUid,
    String courseId,
  ) async {
    try {
      print('DEBUG: 📍 Thêm $studentUid vào course $courseId');

      await _firestore.collection(_collection).doc(studentUid).update({
        'courseIds': FieldValue.arrayUnion([courseId]),
      });

      print('DEBUG: ✅ Thêm thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi thêm: $e');
      throw Exception('Lỗi thêm sinh viên vào course: $e');
    }
  }

  // ========================================
  // HÀM: removeStudentFromCourse()
  // MÔ TẢ: Xóa sinh viên khỏi course
  // ========================================
  static Future<void> removeStudentFromCourse(
    String studentUid,
    String courseId,
  ) async {
    try {
      print('DEBUG: 🗑️ Xóa $studentUid khỏi course $courseId');

      await _firestore.collection(_collection).doc(studentUid).update({
        'courseIds': FieldValue.arrayRemove([courseId]),
      });

      print('DEBUG: ✅ Xóa thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi xóa: $e');
      throw Exception('Lỗi xóa sinh viên khỏi course: $e');
    }
  }

  // ========================================
  // HÀM: addStudentToGroup()
  // MÔ TẢ: Thêm sinh viên vào group
  // ========================================
  static Future<void> addStudentToGroup(
    String studentUid,
    String groupId,
  ) async {
    try {
      print('DEBUG: 📍 Thêm $studentUid vào group $groupId');

      await _firestore.collection(_collection).doc(studentUid).update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });

      print('DEBUG: ✅ Thêm thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi thêm: $e');
      throw Exception('Lỗi thêm sinh viên vào group: $e');
    }
  }

  // ========================================
  // HÀM: removeStudentFromGroup()
  // MÔ TẢ: Xóa sinh viên khỏi group
  // ========================================
  static Future<void> removeStudentFromGroup(
    String studentUid,
    String groupId,
  ) async {
    try {
      print('DEBUG: 🗑️ Xóa $studentUid khỏi group $groupId');

      await _firestore.collection(_collection).doc(studentUid).update({
        'groupIds': FieldValue.arrayRemove([groupId]),
      });

      print('DEBUG: ✅ Xóa thành công');
    } catch (e) {
      print('DEBUG: ❌ Lỗi xóa: $e');
      throw Exception('Lỗi xóa sinh viên khỏi group: $e');
    }
  }

  // ========================================
  // HÀM: getStudentStatistics()
  // MÔ TẢ: Lấy thống kê sinh viên
  // ========================================
  static Future<Map<String, int>> getStudentStatistics() async {
    try {
      print('DEBUG: 📊 Lấy thống kê sinh viên');

      final allStudents = await getAllStudents();
      final activeStudents = allStudents.where((s) => s.isActive).toList();

      return {
        'total': allStudents.length,
        'active': activeStudents.length,
        'inactive': allStudents.length - activeStudents.length,
      };
    } catch (e) {
      print('DEBUG: ❌ Lỗi lấy thống kê: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // ========================================
  // HÀM: listenToStudents()
  // MÔ TẢ: Stream theo dõi sinh viên (tránh index)
  // ========================================
  static Stream<List<StudentModel>> listenToStudents() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          // Filter trên client
          final students = snapshot.docs
              .map((doc) {
                try {
                  return StudentModel.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((s) => s != null && s.role == 'student')
              .cast<StudentModel>()
              .toList();

          // Sort trên client
          students.sort((a, b) => a.name.compareTo(b.name));
          return students;
        });
  }
}