// FILE: bulk_import_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../domain/models/user_model.dart';
import '../../../core/config/users-role.dart';

class BulkImportController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🚀 OPTIMIZED: Create Auth user using shared secondary app (no repeated app initialization)
  Future<String> _createStudentAccountWithSharedApp({
    required FirebaseAuth tempAuth,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ PERFORMANCE: No need to sign out from temporary app - saves 1 network request per user

      return credential.user!.uid;
    } catch (e) {
      print('❌ DEBUG: Failed to create Firebase Auth account for $email: $e');
      rethrow;
    }
  }

  // 🚀 ULTRA-OPTIMIZED: Process single student with WriteBatch (no individual Firestore writes)
  Future<void> _processSingleStudentWithBatch({
    required Map<String, dynamic> record,
    required FirebaseAuth tempAuth,
    required String tempPassword,
    required ImportResult result,
    required WriteBatch firestoreBatch,
  }) async {
    final email = record['email']?.toString().trim() ?? '';
    final name = record['name']?.toString().trim() ?? '';
    final phone = record['phone']?.toString().trim();

    try {
      print('🔄 BULK DEBUG: [PARALLEL+BATCH] Processing: $email');

      // Validation
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
        final existingDoc = existingProfile.docs.first;
        final existingData = existingDoc.data();

        // Add existing user to success records for enrollment
        result.successRecords.add({
          'email': email,
          'name': existingData['name'] ?? name,
          'uid': existingData['uid'] ?? existingDoc.id,
          'isExistingUser': true,
        });

        print('✅ BULK DEBUG: [PARALLEL+BATCH] Existing user processed: $email');
        return;
      }

      // Create new Firebase Auth account ONLY (no Firestore write yet)
      final authUid = await _createStudentAccountWithSharedApp(
        tempAuth: tempAuth,
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

      // 🚀 ADD TO BATCH instead of writing immediately
      firestoreBatch.set(
        _firestore.collection('users').doc(authUid),
        newUser.toFirestore(),
      );

      // Record success (Firestore write will happen later in batch)
      result.successRecords.add({
        'email': email,
        'name': name,
        'uid': authUid,
        'tempPassword': tempPassword,
        'isNewAccount': true,
      });

      print(
          '✅ BULK DEBUG: [PARALLEL+BATCH] Auth created, added to batch: $email');
    } catch (e) {
      print('❌ BULK DEBUG: [PARALLEL+BATCH] Failed to process $email: $e');
      result.failedRecords.add({
        'email': email,
        'name': name,
        'error': e.toString(),
      });
    }
  }

  // Temporary password generator
  String _generateTempPassword() {
    return '123456';
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

    print('🔄 BULK DEBUG: Starting to process ${csvData.length} students');

    // 🚀 OPTIMIZATION: Initialize Secondary Firebase App ONCE outside the loop
    FirebaseApp? tempApp;
    late FirebaseAuth tempAuth;
    try {
      final currentOptions = Firebase.app().options;

      // Try to reuse existing secondary app or create new one
      try {
        tempApp = Firebase.app('SecondaryApp');
      } catch (e) {
        tempApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: currentOptions,
        );
      }

      tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      print(
          '✅ BULK DEBUG: Secondary Firebase App initialized once for batch processing');
    } catch (e) {
      print('❌ BULK DEBUG: Failed to initialize Secondary Firebase App: $e');
      throw Exception('Failed to initialize Firebase for bulk import: $e');
    }

    // 🚀 ULTRA-FAST PROCESSING: Parallel Auth + Batched Firestore
    int batchSize =
        50; // 🔥 OPTIMIZED: Process entire class simultaneously (30-50 students)
    final batches = <List<Map<String, dynamic>>>[];

    for (int i = 0; i < csvData.length; i += batchSize) {
      final end =
          (i + batchSize < csvData.length) ? i + batchSize : csvData.length;
      batches.add(csvData.sublist(i, end));
    }

    print(
        '🚀 BULK DEBUG: Processing ${batches.length} batches of ~$batchSize students each');
    print('🔥 OPTIMIZATION: Using parallel Auth + WriteBatch for Firestore');

    // Collection to store all Firestore writes for batching
    final firestoreBatch = _firestore.batch();

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];
      print(
          '🔄 BULK DEBUG: Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} students)');

      // Process batch concurrently with rate limit retry
      bool batchSuccess = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!batchSuccess && retryCount < maxRetries) {
        try {
          final batchFutures = batch
              .map((record) => _processSingleStudentWithBatch(
                    record: record,
                    tempAuth: tempAuth,
                    tempPassword: tempPassword,
                    result: result,
                    firestoreBatch: firestoreBatch,
                  ))
              .toList();

          await Future.wait(batchFutures);
          batchSuccess = true;
          print('✅ BULK DEBUG: Batch ${batchIndex + 1} completed successfully');
        } catch (e) {
          retryCount++;
          print(
              '❌ BULK DEBUG: Batch ${batchIndex + 1} failed (attempt $retryCount): $e');

          if (e.toString().contains('too-many-requests') ||
              e.toString().contains('rate-limit')) {
            // Reduce batch size and add longer delay for rate limiting
            batchSize = (batchSize / 2)
                .ceil()
                .clamp(5, 50); // 🔥 Keep minimum at 5, max at 50
            print(
                '⚠️ BULK DEBUG: Rate limited! Reducing batch size to $batchSize and retrying...');
            await Future.delayed(Duration(
                milliseconds:
                    500 * retryCount)); // 🔥 Shorter delay for faster recovery
          } else if (retryCount >= maxRetries) {
            print(
                '❌ BULK DEBUG: Batch ${batchIndex + 1} failed permanently after $maxRetries attempts');
            batchSuccess = true; // Exit retry loop
          } else {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      // 🔥 OPTIMIZED: Smaller delay since we use bigger batches
      if (batchIndex < batches.length - 1) {
        await Future.delayed(
            const Duration(milliseconds: 50)); // Reduced from 100ms
      }
    }

    // 🚀 MEGA OPTIMIZATION: Commit ALL Firestore writes in ONE batch operation!
    print(
        '🔥 BULK DEBUG: Committing ALL Firestore writes in one batch operation...');
    try {
      await firestoreBatch.commit();
      print(
          '✅ BULK DEBUG: WriteBatch committed successfully - ALL profiles saved!');
    } catch (e) {
      print('❌ BULK DEBUG: WriteBatch failed: $e');
      // Move successful Auth users to failed records since Firestore write failed
      final authOnlyUsers = result.successRecords
          .where((r) => r['isNewAccount'] == true)
          .toList();
      for (final user in authOnlyUsers) {
        result.failedRecords.add({
          'email': user['email'],
          'name': user['name'],
          'error': 'Auth created but Firestore write failed: $e',
        });
      }
      result.successRecords.removeWhere((r) => r['isNewAccount'] == true);
    }

    print(
        '🔄 BULK DEBUG: Completed processing all students. Success: ${result.successCount}, Failed: ${result.failureCount}');

    // 🧹 CLEANUP: Clean up secondary Firebase App after all operations
    try {
      await tempAuth.signOut(); // Ensure sign out
      // Note: Don't delete the app as it might be reused for future imports
      print('✅ BULK DEBUG: Secondary Firebase App cleaned up');
    } catch (e) {
      print('⚠️ BULK DEBUG: Minor cleanup issue: $e');
    }

    // Optional: verify instructor is still signed in (silent check)
    final finalUser = _firebaseAuth.currentUser;
    if (finalUser == null || finalUser.uid != instructorUid) {
      print('⚠️ BULK DEBUG: Instructor session may have been affected');
    }

    return result;
  }

  // Helper: email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
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
  double get successRate =>
      totalRecords > 0 ? (successCount / totalRecords) * 100 : 0;

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
