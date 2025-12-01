// ========================================
// FILE: csv_import_service.dart
// DESCRIPTION: CSV import service - Updated for UserModel (Removed studentCode)
// ========================================

import 'package:csv/csv.dart';

class CsvValidationResult {
  final String fieldName;
  final String value;
  final String? error;
  final bool isValid;

  CsvValidationResult({
    required this.fieldName,
    required this.value,
    this.error,
    required this.isValid,
  });
}

class StudentImportRecord {
  final int rowIndex;
  final Map<String, dynamic> data;
  final List<CsvValidationResult> validations;
  final bool isValid;
  final String status;
  final String? duplicateEmail;

  StudentImportRecord({
    required this.rowIndex,
    required this.data,
    required this.validations,
    required this.isValid,
    required this.status,
    this.duplicateEmail,
  });

  bool get hasErrors => validations.any((v) => !v.isValid);
  List<String> get errorMessages =>
      validations.where((v) => !v.isValid).map((v) => v.error ?? '').toList();
}

class CsvImportService {
  // ========================================
  // METHOD: parseAndValidateStudentsCsv()
  // DESCRIPTION: Parse CSV and validate records (Only Email and Name required)
  // ========================================
  static Future<List<StudentImportRecord>> parseAndValidateStudentsCsv(
    String csvContent,
    List<String> existingEmails,
  ) async {
    try {
      print('🔄 CSV DEBUG: Starting parseAndValidateStudentsCsv...');

      // Normalize line endings to ensure proper CSV parsing
      final normalizedContent = csvContent
          .replaceAll('\r\n', '\n') // Windows line endings to Unix
          .replaceAll('\r', '\n'); // Mac line endings to Unix

      final List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        shouldParseNumbers:
            false, // Keep all data as strings to avoid type errors
        allowInvalid: false,
        eol: '\n', // Explicitly specify line ending
      ).convert(normalizedContent);

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final headers =
          rows.first.map((h) => h?.toString().trim() ?? '').toList();
      print('🔄 CSV DEBUG: Headers: $headers');

      // Validate required headers (studentCode removed)
      final requiredHeaders = ['email', 'name'];
      final missingHeaders =
          requiredHeaders.where((h) => !headers.contains(h)).toList();

      if (missingHeaders.isNotEmpty) {
        throw Exception(
          'Missing required columns: ${missingHeaders.join(", ")}. '
          'Required: ${requiredHeaders.join(", ")}',
        );
      }

      final records = <StudentImportRecord>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Skip completely empty rows
        if (row.isEmpty ||
            row.every((cell) => cell == null || cell.toString().trim() == '')) {
          continue;
        }

        // Map row to student data
        final user = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = j < row.length ? row[j]?.toString() ?? '' : '';
          user[header] = value.trim();
        }

        // Validate fields
        final validations = _validateUserRecord(user);
        final isFieldValid = validations.every((v) => v.isValid);

        // Check for duplicate email
        final email = user['email']?.toString() ?? '';
        final isDuplicate = existingEmails.contains(email.toLowerCase());

        // Determine status
        String status = 'new';
        String? duplicateEmail;
        if (!isFieldValid) {
          status = 'invalid';
        } else if (isDuplicate) {
          status = 'duplicate';
          duplicateEmail = email;
        }

        records.add(StudentImportRecord(
          rowIndex: i,
          data: user,
          validations: validations,
          isValid: isFieldValid && !isDuplicate,
          status: status,
          duplicateEmail: duplicateEmail,
        ));
      }

      return records;
    } catch (e) {
      rethrow;
    }
  }

  // ========================================
  // METHOD: _validateUserRecord()
  // DESCRIPTION: Validate Email, Name, Phone (studentCode removed)
  // ========================================
  static List<CsvValidationResult> _validateUserRecord(
      Map<String, dynamic> user) {
    final validations = <CsvValidationResult>[];

    // Email validation
    final email = user['email']?.toString() ?? '';
    final emailValid =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email);
    validations.add(CsvValidationResult(
      fieldName: 'email',
      value: email,
      error: !emailValid
          ? email.isEmpty
              ? 'Email is required'
              : 'Invalid email format'
          : null,
      isValid: emailValid,
    ));

    // Name validation
    final name = user['name']?.toString() ?? '';
    final nameValid = name.isNotEmpty && name.length >= 2;
    validations.add(CsvValidationResult(
      fieldName: 'name',
      value: name,
      error: !nameValid
          ? name.isEmpty
              ? 'Name is required'
              : 'Name must be at least 2 characters'
          : null,
      isValid: nameValid,
    ));

    // Phone validation (optional)
    final phone = user['phone']?.toString() ?? '';
    final phoneValid = phone.isEmpty ||
        (phone.isNotEmpty && RegExp(r'^\d{10}$').hasMatch(phone));
    validations.add(CsvValidationResult(
      fieldName: 'phone',
      value: phone,
      error: !phoneValid ? 'Phone must be exactly 10 digits' : null,
      isValid: phoneValid,
    ));

    return validations;
  }

  // ========================================
  // METHOD: validateCsvStructure()
  // DESCRIPTION: Check CSV file structure
  // ========================================
  static Map<String, dynamic> validateCsvStructure(
    String csvContent,
    List<String> requiredColumns,
  ) {
    try {
      print('🔄 CSV DEBUG: Parsing CSV content length: ${csvContent.length}');

      // Normalize line endings to ensure proper CSV parsing
      final normalizedContent = csvContent
          .replaceAll('\r\n', '\n') // Windows line endings to Unix
          .replaceAll('\r', '\n'); // Mac line endings to Unix

      print(
          '🔄 CSV DEBUG: Normalized content length: ${normalizedContent.length}');
      print(
          '🔄 CSV DEBUG: First 100 chars: ${normalizedContent.substring(0, normalizedContent.length > 100 ? 100 : normalizedContent.length)}');

      final List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        shouldParseNumbers:
            false, // Keep all data as strings to avoid type errors
        allowInvalid: false,
        eol: '\n', // Explicitly specify line ending
      ).convert(normalizedContent);

      print('🔄 CSV DEBUG: Parsed ${rows.length} rows');

      if (rows.isEmpty) {
        return {
          'isValid': false,
          'error': 'CSV file is empty',
          'totalRows': 0,
          'validRows': 0,
        };
      }

      print('🔄 CSV DEBUG: First row (headers): ${rows.first}');
      final headers =
          rows.first.map((h) => h?.toString().trim() ?? '').toList();
      print('🔄 CSV DEBUG: Processed headers: $headers');

      // Check required columns
      final missingColumns =
          requiredColumns.where((col) => !headers.contains(col)).toList();

      if (missingColumns.isNotEmpty) {
        return {
          'isValid': false,
          'error':
              'Missing columns: ${missingColumns.join(", ")}. Required: ${requiredColumns.join(", ")}',
          'totalRows': rows.length,
          'validRows': 0,
        };
      }

      // Count non-empty data rows
      int validRows = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isNotEmpty &&
            row.any(
                (cell) => cell != null && cell.toString().trim().isNotEmpty)) {
          validRows++;
        }
      }

      return {
        'isValid': true,
        'totalRows': rows.length,
        'dataRows': validRows,
        'headers': headers,
        'requiredColumns': requiredColumns,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Error reading file: ${e.toString()}',
        'totalRows': 0,
      };
    }
  }

  // ========================================
  // METHOD: getImportSummary()
  // DESCRIPTION: Generate import summary
  // ========================================
  static Map<String, dynamic> getImportSummary(
    List<StudentImportRecord> records, {
    int successCount = 0,
    int failureCount = 0,
  }) {
    final newRecords = records.where((r) => r.status == 'new').toList();
    final duplicateRecords =
        records.where((r) => r.status == 'duplicate').toList();
    final invalidRecords = records.where((r) => r.status == 'invalid').toList();

    return {
      'totalRecords': records.length,
      'newCount': newRecords.length,
      'duplicateCount': duplicateRecords.length,
      'invalidCount': invalidRecords.length,
      'successCount': successCount,
      'failureCount': failureCount,
      'duplicateEmails': duplicateRecords
          .map((r) => r.duplicateEmail)
          .whereType<String>()
          .toList(),
      'invalidRecords': invalidRecords,
    };
  }
}
