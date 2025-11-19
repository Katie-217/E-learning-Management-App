import '../../../data/repositories/student/student_repository.dart';
import '../../../domain/models/student_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BulkImportController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // HÀM: importStudents() - FIXED
  // ========================================
  Future<ImportResult> importStudents(
    List<Map<String, dynamic>> csvData,
  ) async {
    print('🔥 BƯỚC 1: Bắt đầu import sinh viên - ${csvData.length} records');
    
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

    for (int i = 0; i < csvData.length; i++) {
      final record = csvData[i];
      try {
        print('🔥 BƯỚC 2: Xử lý record ${i + 1}/${csvData.length}');
        
        // Validate dữ liệu
        final email = record['email']?.toString().trim() ?? '';
        final name = record['name']?.toString().trim() ?? '';
        final studentCode = record['studentCode']?.toString().trim() ?? '';
        final phone = record['phone']?.toString().trim();

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

// --- 2.2: KIỂM TRA TRÙNG LẶP TRONG FIRESTORE ---
        // Chúng ta sẽ dùng studentCode hoặc email để kiểm tra trùng lặp
        // Kiểm tra email đã tồn tại trong Firestore chưa
        final existingProfile = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingProfile.docs.isNotEmpty) {
          throw Exception('Hồ sơ Firestore đã tồn tại với email: $email');
        }

        print('✅ Email và Mã sinh viên chưa được đăng ký trong Firestore');

        // --- 2.3: TẠO MỘT UID MỚI VÀ STUDENT MODEL ---
        
        // Tạo một Document ID mới (UID) bằng cách tạo một doc ref và lấy id của nó
        // Điều này đảm bảo mỗi hồ sơ có một ID duy nhất
        final newDocRef = _firestore.collection('users').doc();
        final uid = newDocRef.id; 
        
        // Tạo StudentModel
        final student = StudentModel(
          uid: uid, // Sử dụng ID Firestore mới tạo làm UID
          email: email,
          name: name,
          displayName: name,
          studentCode: studentCode,
          phone: phone,
          createdAt: DateTime.now(),
          // Bỏ qua các trường liên quan đến Auth nếu cần, nhưng giữ lại các trường Profile
          settings: const StudentSettings(
             language: 'vi',
             theme: 'light',
             status: 'pending', // Có thể đặt là 'pending' vì chưa có tài khoản Auth
          ),
          role: 'student',
          isActive: false, // User này chưa có tài khoản Auth để đăng nhập, nên đặt là false
        );

        // --- 2.4: LƯU VÀO FIRESTORE ---
        await newDocRef.set(student.toFirestore());
        
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

    // Verify instructor vẫn đăng nhập
    final finalUser = _firebaseAuth.currentUser;
    if (finalUser == null || finalUser.uid != instructorUid) {
      print('⚠️ WARNING: Instructor session lost, re-authenticating...');
    } else {
      print('✅ Instructor session maintained: ${finalUser.email}');
    }

    print('🔥 BƯỚC 3: Kết thúc');
    print('✅ Thành công: ${result.successRecords.length}');
    print('❌ Thất bại: ${result.failedRecords.length}');

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
    return 'TempPass${DateTime.now().millisecondsSinceEpoch}@';
  }
}

// ========================================
// CLASS: ImportResult
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