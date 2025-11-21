// FILE: bulk_import_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../domain/models/user_model.dart';
import '../../../core/config/users-role.dart';

class BulkImportController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create Auth user without signing out the current admin
  Future<String> _createStudentAccountWithoutLogout({
    required String email,
    required String password,
  }) async {
    FirebaseApp? tempApp;
    try {
      final currentOptions = Firebase.app().options;
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: currentOptions,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user!.uid;
    } catch (e) {
      rethrow;
    } finally {
      await tempApp?.delete();
    }
  }

  // Main import function
  Future<ImportResult> importStudents(
    List<Map<String, dynamic>> csvData,
  ) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('Instructor must be logged in to import students');
    }

    final instructorUid = currentUser.uid;
    final tempPassword = _generateTempPassword();

    final result = ImportResult(
      dataType: 'students',
      totalRecords: csvData.length,
    );

    for (int i = 0; i < csvData.length; i++) {
      final record = csvData[i];
      try {
        // Extract and validate fields
        final email = record['email']?.toString().trim() ?? '';
        final name = record['name']?.toString().trim() ?? '';
        final phone = record['phone']?.toString().trim();

        if (!_isValidEmail(email)) {
          throw Exception('Invalid email: $email');
        }

        if (name.isEmpty || name.length < 2) {
          throw Exception('Invalid name: must be at least 2 characters');
        }

        // Check for existing profile by email
        final existingProfile = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (existingProfile.docs.isNotEmpty) {
          throw Exception('Profile already exists with email: $email');
        }

        // Create Auth account using secondary app
        final authUid = await _createStudentAccountWithoutLogout(
          email: email,
          password: tempPassword,
        );

        // Create UserModel instance
        final newUser = UserModel(
          uid: authUid,
          email: email,
          name: name,
          displayName: name,
          phoneNumber: phone,
          createdAt: DateTime.now(),
          settings: const UserSettings(
            language: 'vi',
            theme: 'light',
            status: 'active',
          ),
          role: UserRole.student,
          isActive: true,
          isDefault: false,
        );

        // Save to Firestore using Auth UID as document ID
        await _firestore.collection('users').doc(authUid).set(newUser.toFirestore());

        // Record success
        result.successRecords.add({
          'email': email,
          'name': name,
          'uid': authUid,
          'tempPassword': tempPassword,
        });
      } catch (e) {
        result.failedRecords.add({
          'email': record['email'] ?? 'unknown',
          'name': record['name'] ?? 'unknown',
          'error': e.toString(),
        });
      }
    }

    // Optional: verify instructor is still signed in (silent check)
    final finalUser = _firebaseAuth.currentUser;
    if (finalUser == null || finalUser.uid != instructorUid) {
      // Session was lost due to external factors (rare with secondary app)
    }

    return result;
  }

  // Helper: email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Temporary password (change to stronger generator in production if needed)
  String _generateTempPassword() {
    return '123456';
  }
}

// Result container class
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
  double get successRate => totalRecords > 0 ? (successCount / totalRecords) * 100 : 0;

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
    return 'Success: $successCount / Failed: $failureCount (${successRate.toStringAsFixed(1)}%)';
  }
}