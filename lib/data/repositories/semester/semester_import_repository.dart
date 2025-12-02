// ========================================
// FILE: semester_import_repository.dart
// MÔ TẢ: Repository cho CSV parsing - CHỈ xử lý file và dữ liệu thô
// Clean Architecture: Data Layer
// ========================================

import 'package:csv/csv.dart';
import '../../../domain/models/semester_import_models.dart';

class SemesterImportRepository {
  // ========================================
  // HÀM: parseCsvFile()
  // MÔ TẢ: Parse CSV file thành RawCsvRecord - CHỈ xử lý dữ liệu thô
  // ========================================
  static Future<List<RawCsvRecord>> parseCsvFile(String csvContent) async {
    try {
      // Clean CSV content - remove BOM and invisible characters
      String cleanedContent = _sanitizeCsvContent(csvContent);

      // Force manual CSV parsing to avoid library issues with line breaks
      final lines = cleanedContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      print('DEBUG: 📝 Manual parsing: ${lines.length} lines found');

      if (lines.isEmpty) {
        throw Exception('No valid lines found in CSV file');
      }

      // Manual CSV parsing - more reliable for Windows files
      final rows = lines.map<List<dynamic>>((line) {
        return line.split(',').map((cell) => cell.trim()).toList();
      }).toList();

      print('DEBUG: ✅ Manual CSV parsing complete: ${rows.length} rows');

      if (rows.isEmpty) throw Exception('CSV file is empty');

      // Clean and normalize headers - safe toString() conversion
      final headers =
          rows.first.map((h) => _sanitizeHeader(h?.toString() ?? '')).toList();

      print(
          'DEBUG: 🔍 Cleaned headers: ${headers.map((h) => "\"$h\"").join(", ")}');

      // Validate required columns with case-insensitive matching
      // Support both "Semester"/"templateId" and "Year"/"year" formats
      final requiredSemesterColumn = headers.any((h) =>
          h.toLowerCase() == 'semester' || h.toLowerCase() == 'templateid');
      final requiredYearColumn = headers.any((h) => h.toLowerCase() == 'year');

      final missingColumns = <String>[];
      if (!requiredSemesterColumn) {
        missingColumns.add('Semester (or templateId)');
      }
      if (!requiredYearColumn) {
        missingColumns.add('Year');
      }

      if (missingColumns.isNotEmpty) {
        throw Exception(
            'Missing required columns: ${missingColumns.join(", ")}. '
            'Required: Semester, Year. '
            'Found headers: ${headers.map((h) => "\"$h\"").join(", ")}');
      }

      final records = <RawCsvRecord>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty ||
            row.every(
                (cell) => cell == null || cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        final recordMap = <String, dynamic>{};
        for (int j = 0; j < headers.length; j++) {
          final header = headers[j];
          final value = j < row.length ? row[j]?.toString().trim() ?? '' : '';
          recordMap[header] = value;
        }

        records.add(RawCsvRecord.fromMap(recordMap, i));
      }

      print('DEBUG: ✅ Parsed ${records.length} raw CSV records');
      return records;
    } catch (e) {
      print('DEBUG: ❌ Error parsing CSV: $e');
      rethrow;
    }
  }

  // ========================================
  // HÀM: _sanitizeCsvContent()
  // MÔ TẢ: Làm sạch CSV content - loại bỏ BOM và ký tự ẩn
  // ========================================
  static String _sanitizeCsvContent(String content) {
    // Remove BOM (Byte Order Mark) - common in Windows/Excel files
    String cleaned = content;

    // Remove UTF-8 BOM (EF BB BF)
    if (cleaned.startsWith('\uFEFF')) {
      cleaned = cleaned.substring(1);
      print('DEBUG: 🧹 Removed UTF-8 BOM from CSV');
    }

    // Remove UTF-16 BOM variants
    if (cleaned.startsWith('\uFFFE') || cleaned.startsWith('\uFEFF')) {
      cleaned = cleaned.substring(1);
      print('DEBUG: 🧹 Removed UTF-16 BOM from CSV');
    }

    // Normalize line endings FIRST - critical for Windows files
    cleaned = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Advanced line break detection and repair
    final lines = cleaned.split('\n');
    print('DEBUG: 🔍 Initial split found ${lines.length} lines');

    if (lines.length <= 1 && cleaned.length > 50) {
      print(
          'DEBUG: ⚠️ WARNING: File appears to be one long line - attempting repair');

      // Try to detect pattern and fix line breaks
      // Look for common patterns like: sometext,number,textS1,number,text
      String repairedContent = cleaned;

      // Pattern: textS1, textS2, textS3 (semester codes)
      repairedContent = repairedContent.replaceAllMapped(
          RegExp(r'([^,\s]+S[123]),(\s*\d{4})'),
          (match) => '${match.group(1)},${match.group(2)}\n');

      // Alternative: look for year patterns followed by semester codes
      repairedContent = repairedContent.replaceAllMapped(
          RegExp(r'(\d{4}[^,]*)(S[123])'),
          (match) => '${match.group(1)}\n${match.group(2)}');

      final repairedLines = repairedContent
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      print(
          'DEBUG: 🔧 Repair attempt resulted in ${repairedLines.length} lines');

      if (repairedLines.length > lines.length) {
        cleaned = repairedContent;
        print('DEBUG: ✅ Successfully repaired line breaks');
      }
    }
    return cleaned;
  }

  // ========================================
  // HÀM: _sanitizeHeader()
  // MÔ TẢ: Làm sạch header - loại bỏ quotes và ký tự thừa
  // ========================================
  static String _sanitizeHeader(String header) {
    String cleaned = header.trim();

    // Remove surrounding quotes (single or double)
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith('\'') && cleaned.endsWith('\''))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // Remove any remaining invisible characters
    cleaned = cleaned.replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '');

    // Trim again after cleaning
    cleaned = cleaned.trim();

    return cleaned;
  }

  // ========================================
  // HÀM: validateCsvStructure()
  // MÔ TẢ: Validate basic CSV structure
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
          'error': 'CSV file is empty',
          'totalRows': 0,
          'validRows': 0,
        };
      }

      final headers =
          rows.first.map((h) => (h?.toString() ?? '').trim()).toList();

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
              'Missing required columns: ${missingColumns.join(", ")}. Required: ${requiredColumns.join(", ")}',
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
        'error': 'Error reading file: ${e.toString()}',
        'totalRows': 0,
      };
    }
  }
}
