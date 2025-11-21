// ========================================
// FILE: semester_import_models.dart
// MÔ TẢ: Models cho semester import workflow
// Clean Architecture: Domain Layer
// ========================================

import 'semester_model.dart';

// ========================================
// MODEL: RawCsvRecord - Dữ liệu thô từ CSV
// ========================================
class RawCsvRecord {
  final int rowIndex;
  final String templateId;
  final String year;
  final String? name;
  final Map<String, dynamic> originalData;

  const RawCsvRecord({
    required this.rowIndex,
    required this.templateId,
    required this.year,
    this.name,
    required this.originalData,
  });

  factory RawCsvRecord.fromMap(Map<String, dynamic> map, int rowIndex) {
    return RawCsvRecord(
      rowIndex: rowIndex,
      templateId: map['templateId']?.toString().trim() ?? '',
      year: map['year']?.toString().trim() ?? '',
      name: map['name']?.toString().trim(),
      originalData: map,
    );
  }
}

// ========================================
// MODEL: SemesterImportItem - Item đã được validate
// ========================================
class SemesterImportItem {
  final RawCsvRecord rawRecord;
  final ImportItemStatus status;
  final List<String> validationErrors;
  final String? generatedCode;
  final SemesterModel? previewSemester;

  const SemesterImportItem({
    required this.rawRecord,
    required this.status,
    required this.validationErrors,
    this.generatedCode,
    this.previewSemester,
  });

  bool get isValid => status == ImportItemStatus.willBeAdded;
  bool get isExisting => status == ImportItemStatus.exists;
  bool get isInvalid => status == ImportItemStatus.invalid;
}

// ========================================
// ENUM: ImportItemStatus
// ========================================
enum ImportItemStatus {
  willBeAdded,
  exists,
  invalid,
}

// ========================================
// MODEL: ImportSummary - Thống kê tổng hợp
// ========================================
class ImportSummary {
  final int totalRecords;
  final int newCount;
  final int existingCount;
  final int invalidCount;
  final double validPercentage;
  final String yearRange;
  final int totalDurationDays;

  const ImportSummary({
    required this.totalRecords,
    required this.newCount,
    required this.existingCount,
    required this.invalidCount,
    required this.validPercentage,
    required this.yearRange,
    required this.totalDurationDays,
  });

  factory ImportSummary.calculate(List<SemesterImportItem> items) {
    final newItems = items.where((i) => i.isValid).toList();
    final existingItems = items.where((i) => i.isExisting).toList();
    final invalidItems = items.where((i) => i.isInvalid).toList();

    // Tính phần trăm hợp lệ
    final validPercentage =
        items.isEmpty ? 0.0 : (newItems.length / items.length) * 100;

    // Tính dải năm
    final years = newItems
        .map((i) => i.previewSemester?.year ?? 0)
        .where((year) => year > 0)
        .toSet()
        .toList();
    years.sort();

    final yearRange = years.isEmpty
        ? 'N/A'
        : years.length == 1
            ? years.first.toString()
            : '${years.first} - ${years.last}';

    // Tính tổng số ngày học
    final totalDays = newItems
        .map((i) =>
            i.previewSemester?.endDate
                .difference(i.previewSemester!.startDate)
                .inDays ??
            0)
        .fold(0, (sum, days) => sum + days);

    return ImportSummary(
      totalRecords: items.length,
      newCount: newItems.length,
      existingCount: existingItems.length,
      invalidCount: invalidItems.length,
      validPercentage: validPercentage,
      yearRange: yearRange,
      totalDurationDays: totalDays,
    );
  }
}

// ========================================
// MODEL: ImportSessionData - Data hoàn chỉnh cho UI
// ========================================
class ImportSessionData {
  final List<SemesterImportItem> newItems;
  final List<SemesterImportItem> existingItems;
  final List<SemesterImportItem> invalidItems;
  final ImportSummary summary;

  const ImportSessionData({
    required this.newItems,
    required this.existingItems,
    required this.invalidItems,
    required this.summary,
  });

  factory ImportSessionData.fromItems(List<SemesterImportItem> items) {
    final newItems = items.where((i) => i.isValid).toList();
    final existingItems = items.where((i) => i.isExisting).toList();
    final invalidItems = items.where((i) => i.isInvalid).toList();
    final summary = ImportSummary.calculate(items);

    return ImportSessionData(
      newItems: newItems,
      existingItems: existingItems,
      invalidItems: invalidItems,
      summary: summary,
    );
  }

  List<SemesterImportItem> get allItems =>
      [...newItems, ...existingItems, ...invalidItems];
}

// ========================================
// MODEL: ImportResult - Kết quả sau import
// ========================================
class ImportResult {
  final int totalProcessed;
  final int successCount;
  final int failureCount;
  final double successRate;
  final List<SemesterModel> successfulSemesters;
  final List<ImportFailure> failedImports;

  const ImportResult({
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    required this.successRate,
    required this.successfulSemesters,
    required this.failedImports,
  });

  bool get hasSuccesses => successCount > 0;
  bool get hasFailures => failureCount > 0;
  bool get isCompleteSuccess => failureCount == 0 && successCount > 0;
}

// ========================================
// MODEL: ImportFailure - Chi tiết lỗi import
// ========================================
class ImportFailure {
  final SemesterImportItem item;
  final String errorMessage;

  const ImportFailure({
    required this.item,
    required this.errorMessage,
  });
}
