// FILE: bulk_import_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// **MIGRATED TO HTTP CLOUD FUNCTIONS**
///
/// This controller now uses HTTP requests to call Firebase Cloud Functions
/// Works on ALL platforms: Web, Mobile, AND Desktop
///
/// Benefits:
/// - No plugin compatibility issues
/// - Works on Windows/Linux/macOS desktop
/// - Much faster (parallel processing on Google infrastructure)
/// - Manual authentication with ID Token
/// - One request for entire batch
class BulkImportController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Main import function - calls HTTP Cloud Function for bulk user creation
  Future<ImportResult> importStudents(
    List<Map<String, dynamic>> csvData,
  ) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('Instructor must be logged in to import students');
    }

    final result = ImportResult(
      dataType: 'students',
      totalRecords: csvData.length,
    );

    print(
        '🚀 BULK DEBUG: Calling HTTP Cloud Function to create ${csvData.length} users...');
    print('   Using HTTP request with ID Token for authentication');

    try {
      // Get ID Token
      final idToken = await currentUser.getIdToken();
      print('🔑 BULK DEBUG: Got ID Token');

      // Prepare data for Cloud Function
      final studentsData = csvData.map((record) {
        return {
          'email': record['email']?.toString().trim() ?? '',
          'name': record['name']?.toString().trim() ?? '',
          'phone': record['phone']?.toString().trim() ?? '',
        };
      }).toList();

      // Call HTTP Cloud Function
      const functionUrl = 'https://bulkcreateusers-lx2litqtla-uc.a.run.app';

      print('🌐 BULK DEBUG: Sending HTTP POST to $functionUrl');
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'students': studentsData,
        }),
      );

      print('📡 BULK DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'HTTP ${response.statusCode}: ${errorBody['error'] ?? 'Unknown error'}');
      }

      // Parse response
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final successCount = data['successCount'] as int;
      final failureCount = data['failureCount'] as int;
      final successRecords = (data['successRecords'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final failedRecords = (data['failedRecords'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Populate result object
      result.successRecords.addAll(successRecords);
      result.failedRecords.addAll(failedRecords);

      print('✅ BULK DEBUG: HTTP Cloud Function completed!');
      print('   Success: $successCount');
      print('   Failed: $failureCount');
      print(
          '   Success rate: ${((successCount / csvData.length) * 100).toStringAsFixed(1)}%');

      return result;
    } catch (e) {
      print('❌ BULK DEBUG: HTTP Cloud Function call failed: $e');

      // If Cloud Function fails completely, mark all as failed
      for (final record in csvData) {
        result.failedRecords.add({
          'email': record['email'] ?? 'unknown',
          'name': record['name'] ?? 'unknown',
          'error': 'HTTP Cloud Function error: $e',
        });
      }

      throw Exception('Failed to create users via HTTP Cloud Function: $e');
    }
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
