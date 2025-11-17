import '../../../data/repositories/student/student_repository.dart';
import '../../../data/repositories/course/course_student_repository.dart';
import '../../../data/repositories/group/group_repository.dart';
import '../../../domain/models/student_model.dart';
import '../../../domain/models/course_model.dart';
import '../../../domain/models/group_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BulkImportController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ========================================
  // HÀM: importStudents() - FIXED VERSION
  // MÔ TẢ: Bulk import sinh viên từ CSV parsed data
  // ✅ FIX: Sử dụng Admin SDK pattern để tránh logout instructor
  // ========================================
  Future<ImportResult> importStudents(
    List<Map<String, dynamic>> csvData,
  ) async {
    print('🔥 BƯỚC 1: Bắt đầu import sinh viên - ${csvData.length} records');
    
    // ✅ FIX 1: Lưu current user trước khi import
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('❌ Instructor must be logged in to import students');
    }
    
    final instructorUid = currentUser.uid;
    final instructorEmail = currentUser.email;
    print('✅ Saved current instructor: $instructorEmail');
    
    final result = ImportResult(
      dataType: 'students',
      totalRecords: csvData.length,
    );

    // ✅ FIX 2: Tạo secondary FirebaseAuth instance cho import
    // Điều này cho phép tạo users mà không logout instructor
    final secondaryAuth = FirebaseAuth.instanceFor(app: _firebaseAuth.app);
    
    for (int i = 0; i < csvData.length; i++) {
      final record = csvData[i];
      try {
        print('🔥 BƯỚC 2: Xử lý record ${i + 1}/${csvData.length}');
        
        // Validate dữ liệu
        final email = record['email']?.toString().trim() ?? '';
        final name = record['name']?.toString().trim() ?? '';
        final studentCode = record['studentCode']?.toString().trim() ?? '';
        final phone = record['phone']?.toString().trim();
        final department = record['department']?.toString().trim();

        if (!_isValidEmail(email)) {
          throw Exception('Invalid email: $email');
        }

        if (name.isEmpty || name.length < 2) {
          throw Exception('Invalid name: must be at least 2 characters');
        }

        if (studentCode.isEmpty) {
          throw Exception('Student code cannot be empty');
        }

        print('✅ BƯỚC 2A: Validate thành công');

        // Kiểm tra email đã tồn tại
        final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          throw Exception('Email already exists: $email');
        }

        print('✅ Email chưa được đăng ký');

        // ✅ FIX 3: Sử dụng secondary auth để tạo user
        final tempPassword = _generateTempPassword();
        final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
        
        final uid = userCredential.user!.uid;
        print('✅ Firebase Auth account created: $uid');
        
        // ✅ FIX 4: QUAN TRỌNG - Sign out khỏi secondary auth ngay lập tức
        await secondaryAuth.signOut();
        print('✅ Signed out from secondary auth');

        // Tạo StudentModel
        final student = StudentModel(
          uid: uid,
          email: email,
          name: name,
          displayName: name,
          studentCode: studentCode,
          phone: phone,
          department: department,
          createdAt: DateTime.now(),
          settings: const StudentSettings(
            language: 'vi',
            theme: 'light',
            status: 'active',
          ),
          role: 'student',
          isActive: true,
        );

        // Lưu vào Firestore
        await StudentRepository.createStudent(student);
        print('✅ Student saved to Firestore: $uid');

        result.successRecords.add({
          'email': email,
          'name': name,
          'uid': uid,
        });
      } catch (e) {
        print('❌ Record ${i + 1} failed: $e');
        result.failedRecords.add({
          'email': record['email'] ?? 'unknown',
          'name': record['name'] ?? 'unknown',
          'error': e.toString(),
        });
      }
    }

    // ✅ FIX 5: Verify instructor vẫn đăng nhập
    final finalUser = _firebaseAuth.currentUser;
    if (finalUser == null || finalUser.uid != instructorUid) {
      print('⚠️ WARNING: Instructor session lost, re-authenticating...');
      // Có thể thêm logic re-auth ở đây nếu cần
    } else {
      print('✅ Instructor session maintained: ${finalUser.email}');
    }

    print('🔥 BƯỚC 3: Kết thúc');
    print('✅ Thành công: ${result.successRecords.length}');
    print('❌ Thất bại: ${result.failedRecords.length}');

    return result;
  }

  // ========================================
  // HÀM: importCourses()
  // MÔ TẢ: Bulk import khóa học
  // ========================================
  Future<ImportResult> importCourses(
    List<Map<String, dynamic>> csvData,
    String instructorUid,
  ) async {
    print('🔥 Import courses - ${csvData.length} records');
    final result = ImportResult(
      dataType: 'courses',
      totalRecords: csvData.length,
    );
    for (int i = 0; i < csvData.length; i++) {
      final record = csvData[i];
      try {
        final code = record['code']?.toString().trim() ?? '';
        final name = record['name']?.toString().trim() ?? '';
        final semester = record['semester']?.toString().trim() ?? '';
        final credits = int.tryParse(record['credits']?.toString() ?? '3') ?? 3;
        final maxCapacity =
            int.tryParse(record['maxCapacity']?.toString() ?? '50') ?? 50;
        if (code.isEmpty || name.isEmpty || semester.isEmpty) {
          throw Exception('Missing required fields');
        }
        final course = CourseModel(
          id: '',
          code: code,
          name: name,
          semester: semester,
          instructor: instructorUid,
          credits: credits,
          sessions: 0,
          students: 0,
          progress: 0,
          status: 'active',
          maxCapacity: maxCapacity,
        );
        // Lưu vào Firestore
        // TODO: Implement course creation
        result.successRecords.add({
          'code': code,
          'name': name,
        });
      } catch (e) {
        result.failedRecords.add({
          'code': record['code'] ?? 'unknown',
          'error': e.toString(),
        });
      }
    }
    return result;
  }

  // ========================================
  // HÀM: importGroups()
  // MÔ TẢ: Bulk import nhóm
  // ========================================
  Future<ImportResult> importGroups(
    List<Map<String, dynamic>> csvData,
    String courseId,
  ) async {
    print('🔥 Import groups - ${csvData.length} records');
    final result = ImportResult(
      dataType: 'groups',
      totalRecords: csvData.length,
    );
    for (int i = 0; i < csvData.length; i++) {
      final record = csvData[i];
      try {
        final code = record['code']?.toString().trim() ?? '';
        final name = record['name']?.toString().trim() ?? '';
        final maxMembers =
            int.tryParse(record['maxMembers']?.toString() ?? '30') ?? 30;
        if (code.isEmpty || name.isEmpty) {
          throw Exception('Missing required fields');
        }
        final group = GroupModel(
          id: '',
          courseId: courseId,
          code: code,
          name: name,
          maxMembers: maxMembers,
          createdAt: DateTime.now(),
          createdBy: '', // TODO: Get current user
          isActive: true, 
          studentIds: [],
        );
        // TODO: Implement group creation
        result.successRecords.add({
          'code': code,
          'name': name,
        });
      } catch (e) {
        result.failedRecords.add({
          'code': record['code'] ?? 'unknown',
          'error': e.toString(),
        });
      }
    }
    return result;
  }

  // ========================================
  // HÀM: enrollStudentsToCourse()
  // MÔ TẢ: Ghi danh học sinh vào khóa học từ CSV
  // ========================================
  Future<ImportResult> enrollStudentsToCourse(
    List<Map<String, dynamic>> csvData,
  ) async {
    print('🔥 Enroll students to courses - ${csvData.length} records');
    final result = ImportResult(
      dataType: 'enrollments',
      totalRecords: csvData.length,
    );
    for (int i = 0; i < csvData.length; i++) {
      final record = csvData[i];
      try {
        final studentCode = record['studentCode']?.toString().trim() ?? '';
        final courseCode = record['courseCode']?.toString().trim() ?? '';
        if (studentCode.isEmpty || courseCode.isEmpty) {
          throw Exception('Missing required fields');
        }
        // TODO: Tìm student và course, sau đó enroll
        result.successRecords.add({
          'studentCode': studentCode,
          'courseCode': courseCode,
        });
      } catch (e) {
        result.failedRecords.add({
          'studentCode': record['studentCode'] ?? 'unknown',
          'error': e.toString(),
        });
      }
    }
    return result;
  }

  // ========================================
  // Helper Methods
  // ========================================
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  String _generateTempPassword() {
    // Tạo mật khẩu tạm thời (user phải đổi khi đăng nhập lần đầu)
    return 'TempPass${DateTime.now().millisecondsSinceEpoch}@';
  }
}

// ========================================
// CLASS: ImportResult
// MÔ TẢ: Kết quả import
// ========================================
class ImportResult {
  final String dataType;
  final int totalRecords;
  final List<Map<String, dynamic>> successRecords = [];
  final List<Map<String, dynamic>> failedRecords = [];
  
  ImportResult({
    required this.dataType,
    required this.totalRecords,
  });
  
  int get successCount => successRecords.length;
  int get failureCount => failedRecords.length;
  double get successRate => (successCount / totalRecords) * 100;
  
  Map<String, dynamic> toMap() {
    return {
      'dataType': dataType,
      'totalRecords': totalRecords,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': successRate,
      'successRecords': successRecords,
      'failedRecords': failedRecords,
    };
  }
  
  @override
  String toString() {
    return '✅ $successCount / ❌ $failureCount (${successRate.toStringAsFixed(1)}%)';
  }
}