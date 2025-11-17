// ========================================
// FILE: csv_import_service.dart - ENHANCED VERSION
// MÔ TẢ: Service import CSV với validation & duplicate checking
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
  final String status; // 'new', 'duplicate', 'invalid'
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
  // HÀM: parseAndValidateStudentsCsv()
  // MÔ TẢ: Parse CSV và validate từng record (Step 2)
  // ========================================
  static Future<List<StudentImportRecord>> parseAndValidateStudentsCsv(
    String csvContent,
    List<String> existingEmails,
  ) async {
    try {
      print('DEBUG: 📄 Parsing students CSV...');

      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Extract headers
      final headers = rows.first.cast<String>().map((h) => h.trim()).toList();
      print('DEBUG: Headers: $headers');

      // Validate headers
      final requiredHeaders = ['email', 'name', 'studentCode'];
      final missingHeaders = requiredHeaders
          .where((h) => !headers.contains(h))
          .toList();

      if (missingHeaders.isNotEmpty) {
        throw Exception(
          'Missing required columns: ${missingHeaders.join(", ")}. '
          'Required: ${requiredHeaders.join(", ")}',
        );
      }

      // Parse data rows với validation
      final records = <StudentImportRecord>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Skip empty rows
        if (row.isEmpty ||
            row.every((cell) => cell == null || cell.toString().trim() == '')) {
          continue;
        }

        // Create student map
        final student = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = j < row.length ? row[j]?.toString() ?? '' : '';
          student[header] = value.trim();
        }

        // Validate từng field
        final validations = _validateStudentRecord(student);
        final isValid = validations.every((v) => v.isValid);

        // Check duplicate
        final email = student['email']?.toString() ?? '';
        final isDuplicate = existingEmails.contains(email.toLowerCase());

        // Determine status
        String status = 'new';
        String? duplicateEmail;
        if (!isValid) {
          status = 'invalid';
        } else if (isDuplicate) {
          status = 'duplicate';
          duplicateEmail = email;
        }

        records.add(StudentImportRecord(
          rowIndex: i,
          data: student,
          validations: validations,
          isValid: isValid && !isDuplicate,
          status: status,
          duplicateEmail: duplicateEmail,
        ));
      }

      print(
          'DEBUG: ✅ Parsed ${records.length} records - New: ${records.where((r) => r.status == 'new').length}, Duplicate: ${records.where((r) => r.status == 'duplicate').length}, Invalid: ${records.where((r) => r.status == 'invalid').length}');
      return records;
    } catch (e) {
      print('DEBUG: ❌ Error parsing CSV: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: _validateStudentRecord()
  // MÔ TẢ: Validate từng field của student
  // ========================================
  static List<CsvValidationResult> _validateStudentRecord(
      Map<String, dynamic> student) {
    final validations = <CsvValidationResult>[];

    // Email validation
    final email = student['email']?.toString() ?? '';
    final emailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
    validations.add(CsvValidationResult(
      fieldName: 'email',
      value: email,
      error: !emailValid
          ? email.isEmpty
              ? 'Email không được để trống'
              : 'Email không hợp lệ'
          : null,
      isValid: emailValid,
    ));

    // Name validation
    final name = student['name']?.toString() ?? '';
    final nameValid = name.isNotEmpty && name.length >= 3;
    validations.add(CsvValidationResult(
      fieldName: 'name',
      value: name,
      error: !nameValid
          ? name.isEmpty
              ? 'Tên không được để trống'
              : 'Tên phải có ít nhất 3 ký tự'
          : null,
      isValid: nameValid,
    ));

    // Student Code validation
    final studentCode = student['studentCode']?.toString() ?? '';
    final codeValid = studentCode.isNotEmpty;
    validations.add(CsvValidationResult(
      fieldName: 'studentCode',
      value: studentCode,
      error: !codeValid ? 'Mã sinh viên không được để trống' : null,
      isValid: codeValid,
    ));

    // Phone validation (tùy chọn)
    final phone = student['phone']?.toString() ?? '';
    final phoneValid = phone.isEmpty ||
        (phone.isNotEmpty && RegExp(r'^\d{10}$').hasMatch(phone));
    validations.add(CsvValidationResult(
      fieldName: 'phone',
      value: phone,
      error: !phoneValid ? 'Số điện thoại phải có 10 chữ số' : null,
      isValid: phoneValid,
    ));

    return validations;
  }

  // ========================================
  // HÀM: validateCsvStructure()
  // MÔ TẢ: Kiểm tra cấu trúc file CSV (Step 1)
  // ========================================
  static Map<String, dynamic> validateCsvStructure(
    String csvContent,
    List<String> requiredColumns,
  ) {
    try {
      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        return {
          'isValid': false,
          'error': 'File CSV trống',
          'totalRows': 0,
          'validRows': 0,
        };
      }

      final headers = rows.first.cast<String>().map((h) => h.trim()).toList();

      // Check required columns
      final missingColumns = <String>[];
      for (final col in requiredColumns) {
        if (!headers.contains(col)) {
          missingColumns.add(col);
        }
      }

      if (missingColumns.isNotEmpty) {
        return {
          'isValid': false,
          'error':
              'Thiếu cột: ${missingColumns.join(", ")}. Bắt buộc có: ${requiredColumns.join(", ")}',
          'totalRows': rows.length,
          'validRows': 0,
        };
      }

      // Count valid data rows
      int validRows = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isNotEmpty && row.any((cell) => cell != null && cell != '')) {
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
        'error': 'Lỗi đọc file: ${e.toString()}',
        'totalRows': 0,
      };
    }
  }

  // ========================================
  // HÀM: getImportSummary()
  // MÔ TẢ: Tính toán thống kê import (Step 4)
  // ========================================
  static Map<String, dynamic> getImportSummary(
    List<StudentImportRecord> records, {
    int successCount = 0,
    int failureCount = 0,
  }) {
    final newRecords = records.where((r) => r.status == 'new').toList();
    final duplicateRecords = records.where((r) => r.status == 'duplicate').toList();
    final invalidRecords = records.where((r) => r.status == 'invalid').toList();

    return {
      'totalRecords': records.length,
      'newCount': newRecords.length,
      'duplicateCount': duplicateRecords.length,
      'invalidCount': invalidRecords.length,
      'successCount': successCount,
      'failureCount': failureCount,
      'duplicateEmails':
          duplicateRecords.map((r) => r.duplicateEmail).toList(),
      'invalidRecords': invalidRecords,
    };
  }
}