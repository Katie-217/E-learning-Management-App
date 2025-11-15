// ========================================
// FILE: semester_repository.dart
// MÔ TẢ: Repository để lưu trữ và lấy dữ liệu Semester
// Clean Architecture: Data Layer
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/semester_model.dart';

class SemesterRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'semesters';

  // ========================================
  // HÀM: createSemesterFromTemplate() - DEPRECATED
  // MÔ TẢ: Legacy method - sẽ được remove sau
  // Khuyến khích dùng createSemester() thay thế
  // ========================================
  @Deprecated('Use createSemester() instead for better architecture')
  Future<String> createSemesterFromTemplate({
    required String templateId,
    required int year,
    String? customDescription,
  }) async {
    throw UnimplementedError(
        'Method deprecated. Use SemesterController.handleCreateSemester() instead');
  }

  // ========================================
  // HÀM: createSemester()
  // MÔ TẢ: Tạo và lưu semester từ SemesterModel đã hoàn chỉnh
  // Dùng cho logic snapshot trong SemesterController
  // ========================================
  Future<String> createSemester(SemesterModel semester) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(semester.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo semester: $e');
    }
  }

  // ========================================
  // HÀM: getAllSemesters()
  // MÔ TẢ: Lấy tất cả semesters từ Firestore
  // ========================================
  Future<List<SemesterModel>> getAllSemesters() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('startDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SemesterModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách semester: $e');
    }
  }

  // ========================================
  // HÀM: getSemesterById()
  // MÔ TẢ: Lấy semester theo ID
  // ========================================
  Future<SemesterModel?> getSemesterById(String semesterId) async {
    try {
      final docSnapshot =
          await _firestore.collection(_collection).doc(semesterId).get();

      if (!docSnapshot.exists) return null;

      return SemesterModel.fromMap({
        ...docSnapshot.data()!,
        'id': docSnapshot.id,
      });
    } catch (e) {
      throw Exception('Lỗi lấy semester: $e');
    }
  }

  // ========================================
  // HÀM: getSemestersByYear()
  // MÔ TẢ: Lấy semesters theo năm
  // ========================================
  Future<List<SemesterModel>> getSemestersByYear(int year) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('year', isEqualTo: year)
          .orderBy('startDate')
          .get();

      return querySnapshot.docs
          .map((doc) => SemesterModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy semesters theo năm: $e');
    }
  }

  // ========================================
  // HÀM: getCurrentActiveSemester()
  // MÔ TẢ: Lấy semester đang hoạt động hiện tại
  // ========================================
  Future<SemesterModel?> getCurrentActiveSemester() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return SemesterModel.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Lỗi lấy semester hiện tại: $e');
    }
  }

  // ========================================
  // HÀM: updateSemester()
  // MÔ TẢ: Cập nhật thông tin semester
  // ========================================
  Future<void> updateSemester(SemesterModel semester) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(semester.id)
          .update(semester.toMap());
    } catch (e) {
      throw Exception('Lỗi cập nhật semester: $e');
    }
  }

  // ========================================
  // HÀM: deactivateSemester()
  // MÔ TẢ: Vô hiệu hóa semester
  // ========================================
  Future<void> deactivateSemester(String semesterId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(semesterId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Lỗi vô hiệu hóa semester: $e');
    }
  }

  // ========================================
  // HÀM: deleteSemester()
  // MÔ TẢ: Xóa semester (chỉ nếu chưa có courses)
  // ========================================
  Future<void> deleteSemester(String semesterId) async {
    try {
      // Kiểm tra xem có courses trong semester này không
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('semesterId', isEqualTo: semesterId)
          .limit(1)
          .get();

      if (coursesSnapshot.docs.isNotEmpty) {
        throw Exception('Không thể xóa semester đã có courses');
      }

      await _firestore.collection(_collection).doc(semesterId).delete();
    } catch (e) {
      throw Exception('Lỗi xóa semester: $e');
    }
  }

  // ========================================
  // HÀM: getSemesterStatistics()
  // MÔ TẢ: Lấy thống kê của semester
  // ========================================
  Future<Map<String, int>> getSemesterStatistics(String semesterId) async {
    try {
      // Đếm courses trong semester
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('semesterId', isEqualTo: semesterId)
          .get();

      // Đếm students trong semester (qua courses)
      int totalStudents = 0;
      for (final courseDoc in coursesSnapshot.docs) {
        final studentsSnapshot = await _firestore
            .collection('course_students')
            .where('courseId', isEqualTo: courseDoc.id)
            .get();
        totalStudents += studentsSnapshot.size;
      }

      return {
        'totalCourses': coursesSnapshot.size,
        'totalStudents': totalStudents,
      };
    } catch (e) {
      throw Exception('Lỗi lấy thống kê semester: $e');
    }
  }

  // ========================================
  // HÀM: searchSemesters()
  // MÔ TẢ: Tìm kiếm semesters
  // ========================================
  Future<List<SemesterModel>> searchSemesters(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .startAt([query]).endAt([query + '\uf8ff']).get();

      return querySnapshot.docs
          .map((doc) => SemesterModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Lỗi tìm kiếm semesters: $e');
    }
  }

  // ========================================
  // HÀM: listenToSemesters()
  // MÔ TẢ: Stream để theo dõi thay đổi semesters
  // ========================================
  Stream<List<SemesterModel>> listenToSemesters() {
    return _firestore
        .collection(_collection)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SemesterModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
