// ========================================
// FILE: group_import_models.dart
// MÔ TẢ: Models cho group CSV import workflow
// ========================================

class GroupImportRow {
  final int rowNumber;
  final String code;
  final String name;
  final String? description;
  final List<String> validationErrors;
  final bool isValid;

  const GroupImportRow({
    required this.rowNumber,
    required this.code,
    required this.name,
    this.description,
    this.validationErrors = const [],
    this.isValid = true,
  });

  GroupImportRow copyWith({
    int? rowNumber,
    String? code,
    String? name,
    String? description,
    List<String>? validationErrors,
    bool? isValid,
  }) {
    return GroupImportRow(
      rowNumber: rowNumber ?? this.rowNumber,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      validationErrors: validationErrors ?? this.validationErrors,
      isValid: isValid ?? this.isValid,
    );
  }
}

class GroupImportSessionData {
  final List<GroupImportRow> rows;
  final int validCount;
  final int errorCount;
  final List<String> duplicateCodes; // Codes that already exist in the course

  const GroupImportSessionData({
    required this.rows,
    required this.validCount,
    required this.errorCount,
    this.duplicateCodes = const [],
  });

  bool get hasErrors => errorCount > 0 || duplicateCodes.isNotEmpty;
  bool get hasValidRows => validCount > 0;
}

class GroupImportResult {
  final int successCount;
  final int failureCount;
  final List<GroupImportFailure> failures;

  const GroupImportResult({
    required this.successCount,
    required this.failureCount,
    this.failures = const [],
  });

  bool get hasSuccesses => successCount > 0;
  bool get hasFailures => failureCount > 0;
}

class GroupImportFailure {
  final int rowNumber;
  final String code;
  final String name;
  final String error;

  const GroupImportFailure({
    required this.rowNumber,
    required this.code,
    required this.name,
    required this.error,
  });
}
