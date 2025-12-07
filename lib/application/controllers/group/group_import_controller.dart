// ========================================
// FILE: group_import_controller.dart
// MÔ TẢ: Controller xử lý import groups từ CSV
// ========================================

import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/group_import_models.dart';
import '../../../domain/models/group_model.dart';

class GroupImportController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========================================
  // Parse CSV content và validate
  // ========================================
  Future<GroupImportSessionData> parseAndValidate({
    required String csvContent,
    required String courseId,
  }) async {
    try {
      // Parse CSV
      final List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
      ).convert(csvContent);

      if (csvTable.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Validate header
      final headers =
          csvTable[0].map((e) => e.toString().toLowerCase().trim()).toList();
      final requiredHeaders = ['code', 'name'];

      for (final required in requiredHeaders) {
        if (!headers.contains(required)) {
          throw Exception('Missing required column: $required');
        }
      }

      // Get column indices
      final codeIdx = headers.indexOf('code');
      final nameIdx = headers.indexOf('name');
      final descIdx =
          headers.contains('description') ? headers.indexOf('description') : -1;

      // Get existing group codes in this course
      final existingCodes = await _getExistingGroupCodes(courseId);

      // Parse data rows
      final rows = <GroupImportRow>[];
      final seenCodes = <String>{};

      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        final code = row[codeIdx].toString().trim();
        final name = row[nameIdx].toString().trim();
        final description = descIdx >= 0 && row.length > descIdx
            ? row[descIdx].toString().trim()
            : null;

        // Validation
        final errors = <String>[];

        if (code.isEmpty) {
          errors.add('Code is required');
        } else {
          // Check duplicate in CSV
          if (seenCodes.contains(code)) {
            errors.add('Duplicate code in CSV');
          } else {
            seenCodes.add(code);
          }

          // Check if already exists in course
          if (existingCodes.contains(code)) {
            errors.add('Group code already exists in this course');
          }
        }

        if (name.isEmpty) {
          errors.add('Name is required');
        }

        rows.add(GroupImportRow(
          rowNumber: i + 1,
          code: code,
          name: name,
          description: description,
          validationErrors: errors,
          isValid: errors.isEmpty,
        ));
      }

      final validCount = rows.where((r) => r.isValid).length;
      final errorCount = rows.where((r) => !r.isValid).length;
      final duplicateCodes = rows
          .where((r) =>
              r.validationErrors.any((e) => e.contains('already exists')))
          .map((r) => r.code)
          .toList();

      return GroupImportSessionData(
        rows: rows,
        validCount: validCount,
        errorCount: errorCount,
        duplicateCodes: duplicateCodes,
      );
    } catch (e) {
      print('ERROR: Failed to parse CSV: $e');
      rethrow;
    }
  }

  // ========================================
  // Get existing group codes in course
  // ========================================
  Future<Set<String>> _getExistingGroupCodes(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('courseId', isEqualTo: courseId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['code']?.toString() ?? '')
          .where((code) => code.isNotEmpty)
          .toSet();
    } catch (e) {
      print('ERROR: Failed to get existing group codes: $e');
      return {};
    }
  }

  // ========================================
  // Import groups to Firestore
  // ========================================
  Future<GroupImportResult> importGroups({
    required String courseId,
    required List<GroupImportRow> rows,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    int successCount = 0;
    final failures = <GroupImportFailure>[];

    // Only import valid rows
    final validRows = rows.where((r) => r.isValid).toList();

    for (final row in validRows) {
      try {
        final groupId = _firestore.collection('groups').doc().id;

        final group = GroupModel(
          id: groupId,
          courseId: courseId,
          code: row.code,
          name: row.name,
          description: row.description,
          createdAt: DateTime.now(),
          createdBy: user.uid,
          isActive: true,
        );

        await _firestore.collection('groups').doc(groupId).set(group.toMap());

        successCount++;
      } catch (e) {
        failures.add(GroupImportFailure(
          rowNumber: row.rowNumber,
          code: row.code,
          name: row.name,
          error: e.toString(),
        ));
      }
    }

    return GroupImportResult(
      successCount: successCount,
      failureCount: failures.length,
      failures: failures,
    );
  }
}
